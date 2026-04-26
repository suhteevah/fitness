import Foundation

/// TRIMP-style training load + acute:chronic ratio + recovery alignment score.
/// Source: docs/TRAINING-INTELLIGENCE.md
public enum TrainingLoad {

    /// Banister TRIMP for a single workout.
    public static func trimp(workout: WorkoutProfile) -> Double {
        let minutes = Double(workout.durationMin)
        let intensity = workout.kind.intensityFactor

        let hrFactor: Double
        if let hr = workout.avgHR {
            let reserve = (Double(hr) - MattPhysiology.restingHRBaseline) /
                          (MattPhysiology.maxHREstimated - MattPhysiology.restingHRBaseline)
            hrFactor = max(0.2, min(1.0, reserve))
        } else {
            hrFactor = intensity
        }

        return minutes * intensity * hrFactor
    }

    /// Sum of TRIMPs over the given workouts (already filtered to desired window).
    public static func totalLoad(_ workouts: [WorkoutProfile]) -> Double {
        workouts.map(trimp(workout:)).reduce(0, +)
    }

    /// Acute:chronic ratio. last7 / avg(last28). Sweet spot 0.8–1.3.
    /// Returns nil if there is not enough chronic history.
    public static func acuteChronicRatio(
        last7Days: [WorkoutProfile],
        last28Days: [WorkoutProfile]
    ) -> Double? {
        guard !last28Days.isEmpty else { return nil }
        let acute = totalLoad(last7Days)
        let chronicAvg = totalLoad(last28Days) / 4.0  // 4 weeks
        guard chronicAvg > 0 else { return nil }
        return acute / chronicAvg
    }

    /// Alignment score — the 10% signal that feeds Physical Health grade.
    /// See docs/GRADING-RUBRIC.md § Training-recovery alignment.
    public static func alignmentScore(weeklyWorkouts: [WorkoutProfile],
                                      recovery: RecoveryScore) -> Double {
        let weeklyTRIMP = totalLoad(weeklyWorkouts)
        Log.assessment.debug("Alignment input: recovery=\(recovery.rawValue) weeklyTRIMP=\(weeklyTRIMP, format: .fixed(precision: 1))")

        switch (recovery, weeklyTRIMP) {
        case (.good, 250...500):         return 0.43
        case (.good, 100..<250):         return 0.30
        case (.good, 500...):            return 0.30
        case (.good, 0..<100):           return 0.10
        case (.moderate, 100...300):     return 0.35
        case (.moderate, 300...):        return 0.15
        case (.moderate, 0..<100):       return 0.25
        case (.poor, 0..<150):           return 0.30
        case (.poor, 150...):            return 0.05
        default:                         return 0.15
        }
    }
}
