import Foundation
import SwiftData

/// Runs the weekly assessment pipeline.
/// Phase 1.5: grades Physical Health (HealthKit + daily JSON), Revenue (manual + projectStatus),
/// Client Work (manual + projectStatus), Product Development (projectStatus).
/// Job Hunting + Time Management still Phase 2 (need Gmail/Calendar).
/// Strategy defaults to .b until the strategic-events harvest matures.
@MainActor
public final class AssessmentEngine {
    private let context: ModelContext
    private let healthKit: HealthKitService

    public init(context: ModelContext, healthKit: HealthKitService = .shared) {
        self.context = context
        self.healthKit = healthKit
    }

    /// Run a full assessment for a period and persist it. Returns the stored record.
    public func runAssessment(for period: (start: Date, end: Date, id: String)) async -> Assessment {
        Log.assessment.info("Running assessment for \(period.id)")

        // 1. Health — prefer daily JSON (from 11pm routine), fall back to live HealthKit query.
        let dailyHealth = DailyDataLoader.loadHealthRange(period.start, period.end)
        let snapshot: HealthMetricsSnapshot

        if !dailyHealth.isEmpty {
            Log.assessment.info("Using \(dailyHealth.count) daily-JSON health entries from routine")
            snapshot = HealthAggregator.weeklySnapshot(
                days: dailyHealth,
                periodStart: period.start,
                periodEnd: period.end,
                periodId: period.id
            )
        } else {
            Log.assessment.info("No daily-JSON found; falling back to live HealthKit query")
            snapshot = await healthKit.fetchWeeklyMetrics(
                periodStart: period.start,
                periodEnd: period.end,
                periodId: period.id
            )
        }

        // 2. Manual entries
        let manual = fetchManualEntries(from: period.start, to: period.end)
        let revenueTotal = manual
            .filter { $0.entryKind == .revenue }
            .compactMap(\.amountUSD)
            .reduce(0, +)
        let activeClientsFromManual = Set(manual.filter { $0.entryKind == .revenue }.compactMap(\.clientName)).count
        let deliverablesFromManual = manual.filter { $0.entryKind == .clientMeeting }.count
        let mealPlanDays = manual
            .filter { $0.entryKind == .mealPlan && ($0.mealPlanFollowed ?? false) }
            .count

        // 3. Training load + alignment score (feeds Physical Health grade)
        let recentWorkouts = manual
            .filter { $0.entryKind == .workout }
            .map { entry in
                WorkoutProfile(
                    kind: WorkoutKind(rawValue: entry.workoutType?.lowercased() ?? "") ?? .walk,
                    durationMin: entry.workoutDurationMin ?? 20,
                    date: entry.date,
                    notes: entry.note
                )
            }
        let recovery = classifyRecovery(snapshot: snapshot)
        let alignmentScore = TrainingLoad.alignmentScore(weeklyWorkouts: recentWorkouts, recovery: recovery)

        // 4. Project status (daily JSON)
        let projectDays = DailyDataLoader.loadProjectStatusRange(period.start, period.end)
        let projectPeriod = ProjectStatusPeriod(
            periodStart: period.start,
            periodEnd: period.end,
            days: projectDays
        )

        // 4b. Abacus financial snapshot (Tailscale-only; nil if not configured / unreachable)
        let abacus = await AbacusService.shared.fetchWeeklySnapshot(
            periodStart: period.start, periodEnd: period.end
        )
        if let abacus {
            Log.assessment.info("Abacus: $\(abacus.totalRevenueWeek, format: .fixed(precision: 2)) revenue, \(abacus.activeClientsCount) active clients, $\(abacus.totalSpendingWeek, format: .fixed(precision: 2)) spending this week")
        }

        // 5. Build the @Model
        let health = HealthMetrics.from(
            snapshot: HealthMetricsSnapshot(
                periodId: snapshot.periodId,
                periodStart: snapshot.periodStart,
                periodEnd: snapshot.periodEnd,
                stepsPerDay: snapshot.stepsPerDay,
                activeCalPerDay: snapshot.activeCalPerDay,
                basalEnergyPerDay: snapshot.basalEnergyPerDay,
                exerciseMinPerWeek: snapshot.exerciseMinPerWeek,
                restingHR: snapshot.restingHR,
                hrv: snapshot.hrv,
                walkingHR: snapshot.walkingHR,
                respiratoryRate: snapshot.respiratoryRate,
                vo2Max: snapshot.vo2Max,
                sleepHoursPerNight: snapshot.sleepHoursPerNight,
                bedtimeSDminutes: snapshot.bedtimeSDminutes,
                deepPlusREMPercent: snapshot.deepPlusREMPercent,
                weightLb: snapshot.weightLb,
                weightDeltaLbPerWeek: snapshot.weightDeltaLbPerWeek,
                trainingAlignmentScore: alignmentScore
            ),
            mealPlanDaysFollowed: mealPlanDays,
            workoutsLogged: recentWorkouts.count
        )

        // 6. Grade each category
        let healthGrade = GradingRubric.gradeHealth(metrics: health)

        // Combine manual + projectStatus + Abacus live data for revenue/client counts.
        // Abacus is the canonical source when present; manual + projectStatus
        // remain as supplementary signal (e.g. for clients with informal billing).
        let abacusRevenue = abacus?.totalRevenueWeek ?? 0
        let abacusActiveClients = abacus?.activeClientsCount ?? 0
        let totalRevenue = max(abacusRevenue, revenueTotal) + (abacusRevenue == 0 ? projectPeriod.totalRevenueUSD : 0)
        let activeClients = max(abacusActiveClients, max(activeClientsFromManual, projectPeriod.activeEngagements))
        let deliverables = deliverablesFromManual + projectPeriod.milestonesHit.count

        let revenueGrade = GradingRubric.gradeRevenue(
            totalRevenueUSD: totalRevenue,
            activePayingClients: activeClients,
            pipelineActivity: manual.count + projectPeriod.days.count + (abacus?.revenueEntries.count ?? 0)
        )
        let clientGrade = GradingRubric.gradeClientWork(
            deliverables: deliverables,
            invoicesSent: projectPeriod.invoicesSent,
            activeEngagements: activeClients
        )

        // Product Development — only if we have project status data
        let productGrade: Grade
        if !projectPeriod.days.isEmpty {
            productGrade = GradingRubric.gradeProductDevelopment(
                linesChangedThisPeriod: projectPeriod.linesChangedThisPeriod,
                commitsThisPeriod: projectPeriod.commitsThisPeriod,
                milestonesHit: projectPeriod.milestonesHit.count
            )
        } else {
            productGrade = .incomplete
        }

        // Strategy: default to .b when project status is available, .incomplete otherwise
        let strategyGrade: Grade = projectPeriod.days.isEmpty ? .incomplete : .b

        let categoryGrades: [GradeCategory: Grade] = [
            .physicalHealth: healthGrade,
            .revenuePipeline: revenueGrade,
            .clientWork: clientGrade,
            .productDevelopment: productGrade,
            .strategyDecisions: strategyGrade,
            .jobHunting: .incomplete,           // Phase 2: Gmail
            .timeManagement: .incomplete,       // Phase 2: Calendar
        ]

        let (overallGrade, overallGPA, isComplete) = GradingRubric.overall(from: categoryGrades)

        let recs = buildRecommendations(
            health: healthGrade, metrics: health,
            revenue: revenueGrade, client: clientGrade,
            product: productGrade, projectPeriod: projectPeriod,
            recovery: recovery
        )

        var sources: [DataSource] = [.manualEntry]
        if !dailyHealth.isEmpty {
            sources.append(.healthKit)   // via routine JSON
        } else {
            sources.append(.healthKit)   // via live query
        }
        if !projectPeriod.days.isEmpty {
            sources.append(.github)      // project harvest approximates GitHub signal
        }
        // Abacus contributes financial signal — bucket under .manualEntry semantically
        // (it's still the user's own ledger), but log separately for traceability.
        if abacus != nil {
            Log.assessment.info("Sources include Abacus live revenue/spending data")
        }

        let assessment = Assessment(
            periodId: period.id,
            periodStart: period.start,
            periodEnd: period.end,
            overallGrade: overallGrade,
            overallGPA: overallGPA,
            categoryGrades: categoryGrades,
            healthMetrics: health,
            isComplete: isComplete,
            notes: buildNotes(dailyCount: dailyHealth.count, projectCount: projectPeriod.days.count),
            recommendations: recs,
            dataSources: sources
        )

        context.insert(assessment)
        do {
            try context.save()
            Log.assessment.info("Saved assessment \(period.id): overall=\(overallGrade.rawValue) gpa=\(overallGPA, format: .fixed(precision: 2)) complete=\(isComplete)")
        } catch {
            Log.assessment.error("Failed to save assessment \(period.id): \(error.localizedDescription)")
        }

        return assessment
    }

    // MARK: - Helpers

    private func fetchManualEntries(from start: Date, to end: Date) -> [ManualEntry] {
        let predicate = #Predicate<ManualEntry> { $0.date >= start && $0.date < end }
        let descriptor = FetchDescriptor<ManualEntry>(predicate: predicate)
        do {
            return try context.fetch(descriptor)
        } catch {
            Log.persistence.error("fetchManualEntries failed: \(error.localizedDescription)")
            return []
        }
    }

    private func classifyRecovery(snapshot: HealthMetricsSnapshot) -> RecoveryScore {
        let baseline = HealthBaseline.p1Baseline

        let hrvNorm: Double = {
            guard let hrv = snapshot.hrv else { return 0.5 }
            return min(1.0, max(0, hrv / max(baseline.hrv, 1)))
        }()
        let sleepNorm: Double = {
            guard let hrs = snapshot.sleepHoursPerNight else { return 0.5 }
            return min(1.0, max(0, hrs / 8.0))
        }()
        let rhrNorm: Double = {
            guard let rhr = snapshot.restingHR else { return 0.5 }
            // Lower RHR = better. Score: 1 at ≤60, 0 at ≥75.
            return min(1.0, max(0, (75.0 - rhr) / 15.0))
        }()
        return RecoveryScore.classify(
            hrvNormalized: hrvNorm,
            sleepNormalized: sleepNorm,
            rhrNormalized: rhrNorm
        )
    }

    private func buildRecommendations(
        health: Grade, metrics: HealthMetrics,
        revenue: Grade, client: Grade,
        product: Grade, projectPeriod: ProjectStatusPeriod,
        recovery: RecoveryScore
    ) -> [String] {
        var out: [String] = []

        if let hrv = metrics.hrv, hrv < 50 {
            out.append("HRV is low (\(Int(hrv)) ms). Prioritize sleep and nutrition.")
        }
        if let hrs = metrics.sleepHoursPerNight, hrs < 7 {
            out.append("Sleep averaging \(String(format: "%.1f", hrs))h/night — target 7.5–9.")
        }
        if let mins = metrics.exerciseMinPerWeek, mins < 30 {
            out.append("Exercise under 30 min/wk. A daily 20-min walk would compound recent gains.")
        }
        if let steps = metrics.stepsPerDay, steps < 5_000 {
            out.append("Step count below 5,000/day. Target 7,500+.")
        }
        if recovery == .poor {
            out.append("Recovery is poor this week — HRV/sleep/RHR trending down. Back off hard sessions.")
        }
        if revenue == .f || revenue == .d {
            out.append("No revenue logged. Invoice active clients (Incognito, First Choice Plastics).")
        }
        if client == .c || client == .d {
            out.append("Client engagements active but thin on billable deliverables.")
        }
        if product == .incomplete {
            out.append("No project-status data yet — register the 11pm routine to grade Product Development.")
        }
        for p in projectPeriod.days.flatMap(\.projects) where !p.blockers.isEmpty {
            out.append("[\(p.name)] Blocker: \(p.blockers.first ?? "")")
        }
        return out
    }

    private func buildNotes(dailyCount: Int, projectCount: Int) -> String {
        "Assessment generated with \(dailyCount) health entries and \(projectCount) project-status entries from the daily routine. Job Hunting + Time Management still Phase 2 (Gmail + Calendar)."
    }
}
