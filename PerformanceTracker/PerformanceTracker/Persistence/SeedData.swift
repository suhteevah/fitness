import Foundation
import SwiftData

/// Seeds the P1 / P2 / P3 historical assessments on first launch so Matt can
/// see his full trajectory from day one. See docs/HISTORICAL-DATA.md.
@MainActor
public enum SeedData {
    /// Insert seed assessments if none exist. Idempotent.
    public static func seedIfNeeded(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Assessment>())) ?? []
        if !existing.isEmpty {
            Log.persistence.info("Seed skipped — \(existing.count) assessments already present")
            return
        }

        Log.persistence.info("Seeding historical assessments P1/P2/P3")
        for assessment in Self.historicalAssessments() {
            context.insert(assessment)
        }
        do {
            try context.save()
            Log.persistence.info("Seed complete")
        } catch {
            Log.persistence.error("Seed save failed: \(error.localizedDescription)")
        }
    }

    static func historicalAssessments() -> [Assessment] {
        let p1Health = HealthMetrics(
            periodId: "2026-W08-P1",
            periodStart: dateFrom("2026-02-16"),
            periodEnd: dateFrom("2026-02-22"),
            stepsPerDay: 7_800,
            activeCalPerDay: 640,
            exerciseMinPerWeek: 50,
            restingHR: 66,
            hrv: 57,
            walkingHR: 107
        )

        let p2Health = HealthMetrics(
            periodId: "2026-W10-P2",
            periodStart: dateFrom("2026-02-23"),
            periodEnd: dateFrom("2026-03-19"),
            stepsPerDay: 4_700,
            activeCalPerDay: 347,
            exerciseMinPerWeek: 13,
            restingHR: 73,
            hrv: 42,
            walkingHR: 117
        )

        let p3Health = HealthMetrics(
            periodId: "2026-W12-P3",
            periodStart: dateFrom("2026-03-20"),
            periodEnd: dateFrom("2026-04-08"),
            stepsPerDay: 4_900,
            activeCalPerDay: 470,
            exerciseMinPerWeek: 43,
            restingHR: 63,
            hrv: 76,
            walkingHR: 107,
            mealPlanDaysFollowed: 6
        )

        let p1 = Assessment(
            periodId: "2026-W08-P1",
            periodStart: dateFrom("2026-02-16"),
            periodEnd: dateFrom("2026-02-22"),
            overallGrade: .cPlus,
            overallGPA: 2.3,
            categoryGrades: [
                .productDevelopment: .aMinus,
                .revenuePipeline: .dMinus,
                .jobHunting: .cMinus,
                .clientWork: .d,
                .physicalHealth: .c,
                .timeManagement: .dPlus,
                .strategyDecisions: .d,
            ],
            healthMetrics: p1Health,
            isComplete: true,
            notes: "Baseline period. 267 commits, 60 repos, $0 revenue. 10+ simultaneous projects, empty calendar.",
            recommendations: [
                "Consolidate projects. Too many parallel tracks.",
                "Start billable client work; building infrastructure isn't revenue.",
            ],
            dataSources: [.healthKit, .manualEntry]
        )

        let p2 = Assessment(
            periodId: "2026-W10-P2",
            periodStart: dateFrom("2026-02-23"),
            periodEnd: dateFrom("2026-03-19"),
            overallGrade: .bPlus,
            overallGPA: 3.3,
            categoryGrades: [
                .productDevelopment: .a,
                .revenuePipeline: .cPlus,
                .jobHunting: .aMinus,
                .clientWork: .c,
                .physicalHealth: .dPlus,
                .timeManagement: .cPlus,
                .strategyDecisions: .aMinus,
            ],
            healthMetrics: p2Health,
            isComplete: true,
            notes: "Health crisis — HRV 42 ms. Jake Brander $550 for Vox Spectre. Kalshi 20x w/4 beta testers. Job Hunter blitz 23 companies.",
            recommendations: [
                "HRV crashed — prioritize recovery via nutrition + sleep.",
                "Kalshi persistence vindicated. Keep running it.",
            ],
            dataSources: [.healthKit, .manualEntry]
        )

        let p3 = Assessment(
            periodId: "2026-W12-P3",
            periodStart: dateFrom("2026-03-20"),
            periodEnd: dateFrom("2026-04-08"),
            overallGrade: .aMinus,
            overallGPA: 3.7,
            categoryGrades: [
                .productDevelopment: .aPlus,
                .revenuePipeline: .b,
                .jobHunting: .aMinus,
                .clientWork: .bPlus,
                .physicalHealth: .bMinus,
                .timeManagement: .b,
                .strategyDecisions: .a,
            ],
            healthMetrics: p3Health,
            isComplete: true,
            notes: "ClaudioOS 294K lines. HRV 42→86. Two active clients (Incognito + FCP). 6K applications.",
            recommendations: [
                "Add quality filtering to Job Hunter — stop APAC AE roles.",
                "Invoice Incognito and First Choice.",
                "20-minute walk daily — HRV primed to go higher.",
            ],
            dataSources: [.healthKit, .manualEntry]
        )

        return [p1, p2, p3]
    }
}
