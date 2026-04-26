import Foundation
import SwiftData
import Observation

@Observable
@MainActor
public final class HealthViewModel {
    public var snapshot: HealthMetricsSnapshot?
    public var recent: [HealthMetrics] = []
    public var mealPlanFollowedToday: Bool = false
    public var isLoading: Bool = false

    // Training Intelligence
    public var weeklyTRIMP: Double = 0
    public var acuteChronicRatio: Double? = nil
    public var recovery: RecoveryScore = .moderate
    public var mealRecommendation: MealRecommender.Recommendation? = nil

    private let context: ModelContext
    private let healthKit: HealthKitService

    public init(context: ModelContext, healthKit: HealthKitService = .shared) {
        self.context = context
        self.healthKit = healthKit
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        let start = Date.now.startOfISOWeek()
        let end = Date.now.endOfISOWeek()
        let id = Date.now.isoPeriodId

        // Prefer daily JSON (from 11pm routine) over live HealthKit query
        let dailyEntries = DailyDataLoader.loadHealthRange(start, end)
        if !dailyEntries.isEmpty {
            snapshot = HealthAggregator.weeklySnapshot(
                days: dailyEntries, periodStart: start, periodEnd: end, periodId: id
            )
        } else {
            snapshot = await healthKit.fetchWeeklyMetrics(periodStart: start, periodEnd: end, periodId: id)
        }
        await loadTrainingIntelligence(periodStart: start, periodEnd: end)

        let desc = FetchDescriptor<HealthMetrics>(
            sortBy: [SortDescriptor(\HealthMetrics.periodStart, order: .reverse)]
        )
        recent = (try? context.fetch(desc)) ?? []
        mealPlanFollowedToday = isMealPlanLoggedToday()
    }

    public func toggleMealPlanToday() {
        let today = Calendar.current.startOfDay(for: .now)
        if mealPlanFollowedToday {
            // Remove today's entry
            let desc = FetchDescriptor<ManualEntry>(
                predicate: #Predicate { $0.kind == "mealPlan" && $0.date >= today }
            )
            if let entries = try? context.fetch(desc) {
                for e in entries { context.delete(e) }
            }
        } else {
            let entry = ManualEntry(kind: .mealPlan, date: .now, mealPlanFollowed: true)
            context.insert(entry)
        }
        try? context.save()
        mealPlanFollowedToday.toggle()
        Log.viewModel.info("Meal plan toggled → \(self.mealPlanFollowedToday)")
    }

    public func logWorkout(type: String, durationMin: Int) {
        let entry = ManualEntry(
            kind: .workout,
            workoutType: type,
            workoutDurationMin: durationMin
        )
        context.insert(entry)
        try? context.save()
        Log.viewModel.info("Workout logged: \(type) for \(durationMin) min")
    }

    private func isMealPlanLoggedToday() -> Bool {
        let today = Calendar.current.startOfDay(for: .now)
        let desc = FetchDescriptor<ManualEntry>(
            predicate: #Predicate { $0.kind == "mealPlan" && $0.date >= today }
        )
        return ((try? context.fetch(desc).count) ?? 0) > 0
    }

    private func loadTrainingIntelligence(periodStart: Date, periodEnd: Date) async {
        // Pull workouts from manual entries this week
        let workouts: [WorkoutProfile] = fetchWorkouts(start: periodStart, end: periodEnd)
        weeklyTRIMP = TrainingLoad.totalLoad(workouts)

        // Last 28 days for acute:chronic
        let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: periodEnd) ?? periodStart
        let last28 = fetchWorkouts(start: fourWeeksAgo, end: periodEnd)
        acuteChronicRatio = TrainingLoad.acuteChronicRatio(last7Days: workouts, last28Days: last28)

        // Classify recovery from snapshot
        recovery = classifyRecovery(from: snapshot)

        // Recently-eaten template IDs (last 3 days) — feeds variety scoring.
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now
        let recentLogs = fetchMealLogs(since: threeDaysAgo)
        let recentlyEatenIds = recentLogs.compactMap(\.templateId)

        // Meal recommendation
        let today = Calendar.current.startOfDay(for: .now)
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let todayWorkouts = workouts.filter { $0.date >= today && $0.date < todayEnd }
        let mealContext = MealRecommender.Context(
            todayWorkouts: todayWorkouts,
            tomorrowPlannedKind: nil,
            recovery: recovery,
            recentlyEatenTemplateIds: recentlyEatenIds
        )
        mealRecommendation = MealRecommender.recommend(context: mealContext)
    }

    private func fetchMealLogs(since: Date) -> [EatenMealLog] {
        let desc = FetchDescriptor<EatenMealLog>(
            predicate: #Predicate { $0.date >= since },
            sortBy: [SortDescriptor(\EatenMealLog.date, order: .reverse)]
        )
        return (try? context.fetch(desc)) ?? []
    }

    /// Log a meal that Matt actually ate. Refreshes recommendation on next load.
    public func logEatenMeal(_ rec: MealRecommender.Recommendation) {
        let log = EatenMealLog.from(recommendation: rec)
        context.insert(log)
        try? context.save()
        Log.viewModel.info("Logged meal: \(rec.template.name) [\(rec.template.id)]")
        // Re-derive recommendation immediately so UI reflects variety penalty
        Task { await load() }
    }

    private func fetchWorkouts(start: Date, end: Date) -> [WorkoutProfile] {
        let desc = FetchDescriptor<ManualEntry>(
            predicate: #Predicate { $0.kind == "workout" && $0.date >= start && $0.date < end }
        )
        let entries = (try? context.fetch(desc)) ?? []
        return entries.map { entry in
            WorkoutProfile(
                kind: WorkoutKind(rawValue: entry.workoutType?.lowercased() ?? "walk") ?? .walk,
                durationMin: entry.workoutDurationMin ?? 20,
                date: entry.date,
                notes: entry.note
            )
        }
    }

    private func classifyRecovery(from snap: HealthMetricsSnapshot?) -> RecoveryScore {
        guard let snap else { return .moderate }
        let baseline = HealthBaseline.p1Baseline
        let hrvNorm = snap.hrv.map { min(1.0, max(0, $0 / max(baseline.hrv, 1))) } ?? 0.5
        let sleepNorm = snap.sleepHoursPerNight.map { min(1.0, max(0, $0 / 8.0)) } ?? 0.5
        let rhrNorm = snap.restingHR.map { min(1.0, max(0, (75.0 - $0) / 15.0)) } ?? 0.5
        return RecoveryScore.classify(
            hrvNormalized: hrvNorm, sleepNormalized: sleepNorm, rhrNormalized: rhrNorm
        )
    }
}
