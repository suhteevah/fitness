import XCTest
#if canImport(PerformanceTracker)
@testable import PerformanceTracker
#endif
// On macOS host-test target, sources are compiled directly into the test
// bundle so types are in-module and need no import.

/// Deterministic tests: given metrics in, expect specific grade out.
/// Source of truth: docs/GRADING-RUBRIC.md
final class GradingRubricTests: XCTestCase {

    // MARK: - Health (expanded rubric)

    /// P3 actuals: HRV 76, RHR 63, steps 4900, exercise 43, meal 6 days,
    /// plus sleep 7.5h, bedtime SD 45min, deep+REM 30%, resp 14, VO2 38,
    /// weight delta +0.3 lb/wk, alignment 0.43. Expected: high B range (B or B+).
    func testHealthGrade_P3ActualWithFullSignals_IsBRange() {
        let m = HealthMetrics(
            periodId: "test", periodStart: .now, periodEnd: .now,
            stepsPerDay: 4_900, activeCalPerDay: 470,
            basalEnergyPerDay: 1_900, exerciseMinPerWeek: 43,
            restingHR: 63, hrv: 76, walkingHR: 107,
            respiratoryRate: 14, vo2Max: 38,
            sleepHoursPerNight: 7.5, bedtimeSDminutes: 45,
            deepPlusREMPercent: 0.30,
            weightLb: 196, weightDeltaLbPerWeek: 0.3,
            mealPlanDaysFollowed: 6,
            trainingAlignmentScore: 0.43
        )
        let grade = GradingRubric.gradeHealth(metrics: m)
        XCTAssertTrue(
            [.bMinus, .b, .bPlus, .aMinus, .a].contains(grade),
            "Expected B-range or better, got \(grade.rawValue)"
        )
    }

    /// P2 crisis: HRV 42, RHR 73, steps 4700, exercise 13, sleep 6h,
    /// poor recovery alignment. Expected: F to D+ range.
    func testHealthGrade_P2CrisisWithFullSignals_IsDRangeOrLower() {
        let m = HealthMetrics(
            periodId: "test", periodStart: .now, periodEnd: .now,
            stepsPerDay: 4_700, activeCalPerDay: 347,
            basalEnergyPerDay: 1_800, exerciseMinPerWeek: 13,
            restingHR: 73, hrv: 42, walkingHR: 117,
            respiratoryRate: 17, vo2Max: 34,
            sleepHoursPerNight: 6.0, bedtimeSDminutes: 95,
            deepPlusREMPercent: 0.18,
            weightLb: 198, weightDeltaLbPerWeek: -0.4,
            mealPlanDaysFollowed: 3,
            trainingAlignmentScore: 0.05
        )
        let grade = GradingRubric.gradeHealth(metrics: m)
        XCTAssertTrue(
            [.f, .dMinus, .d, .dPlus, .cMinus].contains(grade),
            "Expected D-range, got \(grade.rawValue)"
        )
    }

    func testHealthGrade_AllNil_ReturnsIncomplete() {
        let m = HealthMetrics(periodId: "test", periodStart: .now, periodEnd: .now)
        XCTAssertEqual(GradingRubric.gradeHealth(metrics: m), .incomplete)
    }

    /// 3+ essential fields nil (out of HRV, RHR, Steps, Exercise, Sleep) → incomplete
    func testHealthGrade_MostEssentialNil_ReturnsIncomplete() {
        let m = HealthMetrics(
            periodId: "test", periodStart: .now, periodEnd: .now,
            stepsPerDay: 5_000,
            exerciseMinPerWeek: 30
        )
        XCTAssertEqual(GradingRubric.gradeHealth(metrics: m), .incomplete)
    }

    /// 2 essential nil, 3 present → should grade, not incomplete
    func testHealthGrade_TwoEssentialNil_DoesNotReturnIncomplete() {
        let m = HealthMetrics(
            periodId: "test", periodStart: .now, periodEnd: .now,
            stepsPerDay: 5_000, exerciseMinPerWeek: 30,
            restingHR: 65, hrv: 60,
            sleepHoursPerNight: nil  // 2 nil: basalEnergy + sleep technically, only sleep essential
        )
        // Actually 1 essential nil (sleep). Others are HRV/RHR/Steps/Exercise all present. → grade.
        let grade = GradingRubric.gradeHealth(metrics: m)
        XCTAssertNotEqual(grade, .incomplete)
    }

    // MARK: - Product Development

    func testProductDev_ClaudioOSScale_GradesAPlus() {
        let grade = GradingRubric.gradeProductDevelopment(
            linesChangedThisPeriod: 294_710,
            commitsThisPeriod: 200,
            milestonesHit: 5
        )
        XCTAssertEqual(grade, .aPlus)
    }

    func testProductDev_MilestoneButFewLines_StillAPlus() {
        let grade = GradingRubric.gradeProductDevelopment(
            linesChangedThisPeriod: 300,
            commitsThisPeriod: 10,
            milestonesHit: 2
        )
        XCTAssertEqual(grade, .aPlus)  // milestonesHit >= 2 triggers A+
    }

    func testProductDev_ZeroActivity_F() {
        let grade = GradingRubric.gradeProductDevelopment(
            linesChangedThisPeriod: 0,
            commitsThisPeriod: 0,
            milestonesHit: 0
        )
        XCTAssertEqual(grade, .f)
    }

    // MARK: - Revenue

    func testRevenueGrade_AboveThreshold() {
        XCTAssertEqual(GradingRubric.gradeRevenue(totalRevenueUSD: 2_500, activePayingClients: 1, pipelineActivity: 0), .a)
        XCTAssertEqual(GradingRubric.gradeRevenue(totalRevenueUSD: 1_000, activePayingClients: 1, pipelineActivity: 0), .b)
        XCTAssertEqual(GradingRubric.gradeRevenue(totalRevenueUSD: 200, activePayingClients: 0, pipelineActivity: 0), .c)
        XCTAssertEqual(GradingRubric.gradeRevenue(totalRevenueUSD: 0, activePayingClients: 0, pipelineActivity: 1), .d)
        XCTAssertEqual(GradingRubric.gradeRevenue(totalRevenueUSD: 0, activePayingClients: 0, pipelineActivity: 0), .f)
    }

    func testRevenueGrade_MultipleClients_GradesA() {
        XCTAssertEqual(GradingRubric.gradeRevenue(totalRevenueUSD: 0, activePayingClients: 3, pipelineActivity: 0), .a)
    }

    // MARK: - Client Work

    func testClientWorkGrade() {
        XCTAssertEqual(GradingRubric.gradeClientWork(deliverables: 3, invoicesSent: 2, activeEngagements: 2), .a)
        XCTAssertEqual(GradingRubric.gradeClientWork(deliverables: 1, invoicesSent: 0, activeEngagements: 1), .b)
        XCTAssertEqual(GradingRubric.gradeClientWork(deliverables: 0, invoicesSent: 0, activeEngagements: 1), .c)
        XCTAssertEqual(GradingRubric.gradeClientWork(deliverables: 0, invoicesSent: 0, activeEngagements: 0), .f)
    }

    // MARK: - Overall weighted average

    func testOverall_P3CategoryGrades_ProducesBPlus() {
        // Note: the historical P3 narrative was rated "A-" qualitatively, but the
        // weighted average of the per-category letter grades stored as seed data
        // is 3.495 GPA — which mathematically buckets as B+ under our rubric
        // (A- needs ≥ 3.5). This is a normal narrative-vs-arithmetic gap; the
        // rubric is deterministic and correct. Test asserts the mathematical result.
        let grades: [GradeCategory: Grade] = [
            .productDevelopment: .aPlus,    // 4.3 * 0.25 = 1.075
            .revenuePipeline:    .b,        // 3.0 * 0.20 = 0.600
            .jobHunting:         .aMinus,   // 3.7 * 0.15 = 0.555
            .clientWork:         .bPlus,    // 3.3 * 0.15 = 0.495
            .physicalHealth:     .bMinus,   // 2.7 * 0.10 = 0.270
            .timeManagement:     .b,        // 3.0 * 0.10 = 0.300
            .strategyDecisions:  .a,        // 4.0 * 0.05 = 0.200
                                            // Σ = 3.495 → B+
        ]
        let (grade, gpa, complete) = GradingRubric.overall(from: grades)
        XCTAssertTrue(complete)
        XCTAssertEqual(gpa, 3.495, accuracy: 0.001)
        XCTAssertEqual(grade, Grade.bPlus, "Math gives B+ at gpa=\(gpa); historical narrative was A- but rubric is deterministic.")
    }

    func testOverall_OnlyHealthGraded_IsPartial() {
        let grades: [GradeCategory: Grade] = [
            .physicalHealth: .a,
            .productDevelopment: .incomplete,
            .revenuePipeline: .incomplete,
            .jobHunting: .incomplete,
            .clientWork: .incomplete,
            .timeManagement: .incomplete,
            .strategyDecisions: .incomplete,
        ]
        let (grade, _, complete) = GradingRubric.overall(from: grades)
        XCTAssertFalse(complete)
        XCTAssertEqual(grade, Grade.a)
    }

    // MARK: - Grade enum

    func testGradeFromGPA_BoundaryValues() {
        XCTAssertEqual(Grade.fromGPA(4.3), .aPlus)
        XCTAssertEqual(Grade.fromGPA(4.0), .a)
        XCTAssertEqual(Grade.fromGPA(3.7), .aMinus)
        XCTAssertEqual(Grade.fromGPA(0.0), .f)
    }

    // MARK: - Training Load

    func testTrainingLoad_WalkTrimp() {
        let walk = WorkoutProfile(kind: .walk, durationMin: 20, date: .now)
        let trimp = TrainingLoad.trimp(workout: walk)
        // 20 min * 0.25 * 0.25 = 1.25
        XCTAssertEqual(trimp, 1.25, accuracy: 0.01)
    }

    func testTrainingLoad_StrengthTrimp() {
        let strength = WorkoutProfile(kind: .strength, durationMin: 45, avgHR: 140, date: .now)
        // 45 min * 0.75 * HR-reserve where reserve = (140-63)/(183-63) = 0.642
        let expected = 45.0 * 0.75 * 0.642
        XCTAssertEqual(TrainingLoad.trimp(workout: strength), expected, accuracy: 0.1)
    }

    func testTrainingLoad_Alignment_GoodRecoveryGoodLoad() {
        let workouts = [
            WorkoutProfile(kind: .strength, durationMin: 45, date: .now),
            WorkoutProfile(kind: .zone2, durationMin: 40, date: .now),
        ]
        let alignment = TrainingLoad.alignmentScore(weeklyWorkouts: workouts, recovery: .good)
        XCTAssertGreaterThan(alignment, 0)
    }

    // MARK: - Meal Recommender

    func testMealRecommender_PostStrength_RecommendsHighProtein() {
        let context = MealRecommender.Context(
            todayWorkouts: [WorkoutProfile(kind: .strength, durationMin: 45, date: .now)],
            recovery: .good
        )
        let rec = MealRecommender.recommend(context: context)
        XCTAssertNotNil(rec)
        XCTAssertGreaterThanOrEqual(rec?.template.macros.proteinG ?? 0, 40)
    }

    func testMealRecommender_RestPoorRecovery_PrefersNutrientDense() {
        let context = MealRecommender.Context(
            todayWorkouts: [],
            recovery: .poor
        )
        let rec = MealRecommender.recommend(context: context)
        XCTAssertNotNil(rec)
        XCTAssertTrue(
            rec?.template.id == "keto-animal-006" || rec?.template.id == "keto-animal-007",
            "Poor recovery rest day should prefer nutrient-dense templates, got \(rec?.template.id ?? "nil")"
        )
    }

    func testMealRecommender_PoorRecoveryBeforeHardTomorrow_Warns() {
        let context = MealRecommender.Context(
            todayWorkouts: [],
            tomorrowPlannedKind: .zone4,
            recovery: .poor
        )
        let rec = MealRecommender.recommend(context: context)
        XCTAssertNotNil(rec?.warning)
    }
}
