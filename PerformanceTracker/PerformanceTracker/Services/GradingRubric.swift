import Foundation

/// Pure, deterministic grading logic. Given inputs, always returns the same grade.
/// Source of truth for thresholds: docs/GRADING-RUBRIC.md
public enum GradingRubric {

    /// Maximum score for the health algorithm — sum of every signal's max weight.
    /// 0.86+0.43+0.65+0.22+0.22+0.34+0.34+0.34+0.17+0.17+0.13+0.43 = 4.30
    public static let healthMaxScore: Double = 4.30

    /// Essential inputs — if more than half are nil, we return .incomplete.
    /// Everything else is a nice-to-have; missing = 0 contribution.
    private static func essentialNilCount(_ metrics: HealthMetrics) -> Int {
        let essential: [Double?] = [
            metrics.hrv,
            metrics.restingHR,
            metrics.stepsPerDay,
            metrics.exerciseMinPerWeek,
            metrics.sleepHoursPerNight,
        ]
        return essential.filter { $0 == nil }.count
    }

    /// Grade the Physical Health category.
    /// 12 signals + HRV trend bonus. See docs/GRADING-RUBRIC.md for thresholds.
    public static func gradeHealth(metrics: HealthMetrics,
                                   baseline: HealthBaseline = .p1Baseline) -> Grade {
        let nilCount = essentialNilCount(metrics)
        if nilCount > 2 {  // 3+ essential nil = too sparse to grade
            Log.rubric.warning("Health grade → .incomplete (essential nil = \(nilCount)/5)")
            return .incomplete
        }

        var score: Double = 0

        // 1. HRV — 20% (max 0.86)
        if let hrv = metrics.hrv {
            switch hrv {
            case 60...:          score += 0.86
            case 50..<60:        score += 0.60
            case 40..<50:        score += 0.26
            default:             score += 0
            }
        }

        // 2. Resting HR — 10% (max 0.43)
        if let rhr = metrics.restingHR {
            switch rhr {
            case ..<60.01:       score += 0.43
            case ..<65.01:       score += 0.35
            case ..<70.01:       score += 0.22
            case ..<75.01:       score += 0.10
            default:             score += 0
            }
        }

        // 3. Sleep duration — 15% (max 0.65)
        if let hrs = metrics.sleepHoursPerNight {
            switch hrs {
            case 7.5...9.0:             score += 0.65
            case 7.0..<7.5:             score += 0.45
            case 9.0..<9.51:            score += 0.45
            case 6.0..<7.0:             score += 0.25
            case 9.51..<10:             score += 0.25
            default:                    score += 0.05
            }
        }

        // 4. Sleep consistency (bedtime SD minutes) — 5% (max 0.22)
        if let bedSD = metrics.bedtimeSDminutes {
            switch bedSD {
            case ..<30.01:      score += 0.22
            case ..<60.01:      score += 0.15
            case ..<90.01:      score += 0.08
            default:            score += 0
            }
        }

        // 5. Deep + REM fraction — 5% (max 0.22)
        if let stagesPct = metrics.deepPlusREMPercent {
            switch stagesPct {
            case 0.35...:       score += 0.22
            case 0.25..<0.35:   score += 0.15
            case 0.15..<0.25:   score += 0.08
            default:            score += 0
            }
        }

        // 6. Steps — 8% (max 0.34)
        if let steps = metrics.stepsPerDay {
            switch steps {
            case 7_500...:        score += 0.34
            case 5_000..<7_500:   score += 0.21
            case 3_000..<5_000:   score += 0.10
            default:              score += 0
            }
        }

        // 7. Exercise minutes/week — 8% (max 0.34)
        if let mins = metrics.exerciseMinPerWeek {
            switch mins {
            case 150...:        score += 0.34
            case 75..<150:      score += 0.21
            case 30..<75:       score += 0.10
            default:            score += 0
            }
        }

        // 8. Meal plan adherence — 8% (max 0.34)
        if let days = metrics.mealPlanDaysFollowed {
            switch days {
            case 6...:      score += 0.34
            case 4...5:     score += 0.20
            case 2...3:     score += 0.08
            default:        score += 0
            }
        }

        // 9. Respiratory rate — 4% (max 0.17)
        if let rr = metrics.respiratoryRate {
            let inHealthyRange = rr >= 12 && rr <= 20
            let dev = abs(rr - baseline.respiratoryRate)
            if inHealthyRange && dev <= 1      { score += 0.17 }
            else if inHealthyRange             { score += 0.10 }
            else if dev <= 3                   { score += 0.05 }
            else                               { score += 0 }
        }

        // 10. VO2max — 4% (max 0.17)
        if let vo2 = metrics.vo2Max {
            switch vo2 {
            case 45...:         score += 0.17
            case 40..<45:       score += 0.13
            case 35..<40:       score += 0.09
            case 30..<35:       score += 0.05
            default:            score += 0
            }
        }

        // 11. Body weight trend — 3% (max 0.13)
        if let delta = metrics.weightDeltaLbPerWeek {
            if (0 ... 0.5).contains(delta)      { score += 0.13 }
            else if abs(delta) <= 0.2           { score += 0.09 }
            else                                { score += 0 }
        }

        // 12. Training-recovery alignment — 10% (max 0.43, default 0.15 neutral)
        score += metrics.trainingAlignmentScore ?? 0.15

        // HRV bonus/penalty vs baseline — ±10%
        if let hrv = metrics.hrv, baseline.hrv > 0 {
            if hrv > baseline.hrv * 1.1        { score += 0.43 }
            else if hrv < baseline.hrv * 0.9   { score -= 0.20 }
        }

        let clamped = max(score, 0)
        let grade = Grade.fromScore(clamped, maxScore: healthMaxScore)
        Log.rubric.info("Health grade: score=\(clamped, format: .fixed(precision: 2))/\(healthMaxScore, format: .fixed(precision: 2)) → \(grade.rawValue)")
        return grade
    }

    /// Grade Product Development from harvested project status.
    /// Source: docs/GRADING-RUBRIC.md § Product Development
    public static func gradeProductDevelopment(linesChangedThisPeriod: Int,
                                               commitsThisPeriod: Int,
                                               milestonesHit: Int) -> Grade {
        if linesChangedThisPeriod >= 10_000 || milestonesHit >= 2 { return .aPlus }
        if linesChangedThisPeriod >= 5_000 || milestonesHit >= 1  { return .a }
        if linesChangedThisPeriod >= 2_500                        { return .aMinus }
        if linesChangedThisPeriod >= 1_000                        { return .bPlus }
        if linesChangedThisPeriod >= 250                          { return .b }
        if linesChangedThisPeriod > 0 || commitsThisPeriod > 0    { return .c }
        return .f
    }

    /// Grade Revenue from manual entries.
    public static func gradeRevenue(totalRevenueUSD: Double,
                                    activePayingClients: Int,
                                    pipelineActivity: Int) -> Grade {
        if totalRevenueUSD >= 2_000 || activePayingClients >= 2 { return .a }
        if totalRevenueUSD >= 500                               { return .b }
        if totalRevenueUSD > 0                                  { return .c }
        if pipelineActivity > 0                                 { return .d }
        return .f
    }

    /// Grade Client Work from manual entries + project status.
    public static func gradeClientWork(deliverables: Int,
                                       invoicesSent: Int,
                                       activeEngagements: Int) -> Grade {
        if deliverables >= 2 && invoicesSent >= 1 { return .a }
        if deliverables >= 1                       { return .b }
        if activeEngagements >= 1                  { return .c }
        if activeEngagements == 0 && deliverables == 0 { return .f }
        return .d
    }

    /// Compute weighted-average GPA from per-category grades.
    /// Skips categories with `.incomplete`. Returns (overallGrade, overallGPA, isComplete).
    public static func overall(from categoryGrades: [GradeCategory: Grade]) -> (Grade, Double, Bool) {
        var weightedSum: Double = 0
        var weightUsed: Double = 0
        var complete = true

        for category in GradeCategory.allCases {
            let grade = categoryGrades[category] ?? .incomplete
            if let gpa = grade.gpa {
                weightedSum += gpa * category.weight
                weightUsed += category.weight
            } else {
                complete = false
            }
        }

        guard weightUsed > 0 else { return (.incomplete, 0, false) }
        let gpa = weightedSum / weightUsed
        return (Grade.fromGPA(gpa), gpa, complete && weightUsed > 0.999)
    }
}
