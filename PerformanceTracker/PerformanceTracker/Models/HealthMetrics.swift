import Foundation
import SwiftData

/// Sendable snapshot of weekly health metrics. Produced by HealthKitService (actor),
/// consumed by MainActor code which converts it into a persistent `HealthMetrics` @Model.
/// SwiftData @Model classes are NOT Sendable, so crossing actor boundaries requires this.
/// Source: docs/DATA-SOURCES.md + docs/GRADING-RUBRIC.md
public struct HealthMetricsSnapshot: Sendable {
    public let periodId: String
    public let periodStart: Date
    public let periodEnd: Date

    // Movement / energy
    public let stepsPerDay: Double?
    public let activeCalPerDay: Double?
    public let basalEnergyPerDay: Double?
    public let exerciseMinPerWeek: Double?

    // Cardiovascular
    public let restingHR: Double?
    public let hrv: Double?
    public let walkingHR: Double?
    public let respiratoryRate: Double?
    public let vo2Max: Double?

    // Sleep
    public let sleepHoursPerNight: Double?
    public let bedtimeSDminutes: Double?
    public let deepPlusREMPercent: Double?

    // Body composition
    public let weightLb: Double?
    public let weightDeltaLbPerWeek: Double?

    // Derived / subject
    public let trainingAlignmentScore: Double?

    public init(
        periodId: String, periodStart: Date, periodEnd: Date,
        stepsPerDay: Double? = nil, activeCalPerDay: Double? = nil,
        basalEnergyPerDay: Double? = nil, exerciseMinPerWeek: Double? = nil,
        restingHR: Double? = nil, hrv: Double? = nil, walkingHR: Double? = nil,
        respiratoryRate: Double? = nil, vo2Max: Double? = nil,
        sleepHoursPerNight: Double? = nil, bedtimeSDminutes: Double? = nil,
        deepPlusREMPercent: Double? = nil,
        weightLb: Double? = nil, weightDeltaLbPerWeek: Double? = nil,
        trainingAlignmentScore: Double? = nil
    ) {
        self.periodId = periodId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.stepsPerDay = stepsPerDay
        self.activeCalPerDay = activeCalPerDay
        self.basalEnergyPerDay = basalEnergyPerDay
        self.exerciseMinPerWeek = exerciseMinPerWeek
        self.restingHR = restingHR
        self.hrv = hrv
        self.walkingHR = walkingHR
        self.respiratoryRate = respiratoryRate
        self.vo2Max = vo2Max
        self.sleepHoursPerNight = sleepHoursPerNight
        self.bedtimeSDminutes = bedtimeSDminutes
        self.deepPlusREMPercent = deepPlusREMPercent
        self.weightLb = weightLb
        self.weightDeltaLbPerWeek = weightDeltaLbPerWeek
        self.trainingAlignmentScore = trainingAlignmentScore
    }

    public var availableFieldCount: Int {
        let allFields: [Double?] = [
            stepsPerDay, activeCalPerDay, basalEnergyPerDay, exerciseMinPerWeek,
            restingHR, hrv, walkingHR, respiratoryRate, vo2Max,
            sleepHoursPerNight, bedtimeSDminutes, deepPlusREMPercent,
            weightLb,
        ]
        return allFields.filter { $0 != nil }.count
    }
}

/// Weekly aggregated health metrics persisted to SwiftData.
/// All fields optional — HealthKit may deny access or have no data.
@Model
public final class HealthMetrics {
    public var periodId: String
    public var periodStart: Date
    public var periodEnd: Date

    // Movement / energy
    public var stepsPerDay: Double?
    public var activeCalPerDay: Double?
    public var basalEnergyPerDay: Double?
    public var exerciseMinPerWeek: Double?

    // Cardiovascular
    public var restingHR: Double?
    public var hrv: Double?
    public var walkingHR: Double?
    public var respiratoryRate: Double?
    public var vo2Max: Double?

    // Sleep
    public var sleepHoursPerNight: Double?
    public var bedtimeSDminutes: Double?
    public var deepPlusREMPercent: Double?

    // Body composition
    public var weightLb: Double?
    public var weightDeltaLbPerWeek: Double?

    // Subject-reported
    public var mealPlanDaysFollowed: Int?
    public var workoutsLogged: Int?

    // Derived
    public var trainingAlignmentScore: Double?

    public init(
        periodId: String,
        periodStart: Date,
        periodEnd: Date,
        stepsPerDay: Double? = nil, activeCalPerDay: Double? = nil,
        basalEnergyPerDay: Double? = nil, exerciseMinPerWeek: Double? = nil,
        restingHR: Double? = nil, hrv: Double? = nil, walkingHR: Double? = nil,
        respiratoryRate: Double? = nil, vo2Max: Double? = nil,
        sleepHoursPerNight: Double? = nil, bedtimeSDminutes: Double? = nil,
        deepPlusREMPercent: Double? = nil,
        weightLb: Double? = nil, weightDeltaLbPerWeek: Double? = nil,
        mealPlanDaysFollowed: Int? = nil, workoutsLogged: Int? = nil,
        trainingAlignmentScore: Double? = nil
    ) {
        self.periodId = periodId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.stepsPerDay = stepsPerDay
        self.activeCalPerDay = activeCalPerDay
        self.basalEnergyPerDay = basalEnergyPerDay
        self.exerciseMinPerWeek = exerciseMinPerWeek
        self.restingHR = restingHR
        self.hrv = hrv
        self.walkingHR = walkingHR
        self.respiratoryRate = respiratoryRate
        self.vo2Max = vo2Max
        self.sleepHoursPerNight = sleepHoursPerNight
        self.bedtimeSDminutes = bedtimeSDminutes
        self.deepPlusREMPercent = deepPlusREMPercent
        self.weightLb = weightLb
        self.weightDeltaLbPerWeek = weightDeltaLbPerWeek
        self.mealPlanDaysFollowed = mealPlanDaysFollowed
        self.workoutsLogged = workoutsLogged
        self.trainingAlignmentScore = trainingAlignmentScore
    }

    /// Count of non-nil HealthKit-sourced fields (excludes subject-reported + derived).
    public var availableFieldCount: Int {
        let fields: [Double?] = [
            stepsPerDay, activeCalPerDay, basalEnergyPerDay, exerciseMinPerWeek,
            restingHR, hrv, walkingHR, respiratoryRate, vo2Max,
            sleepHoursPerNight, bedtimeSDminutes, deepPlusREMPercent,
            weightLb,
        ]
        return fields.filter { $0 != nil }.count
    }

    /// Build a HealthMetrics @Model from a Sendable snapshot (main-actor-only).
    @MainActor
    public static func from(snapshot: HealthMetricsSnapshot,
                            mealPlanDaysFollowed: Int? = nil,
                            workoutsLogged: Int? = nil) -> HealthMetrics {
        HealthMetrics(
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
            mealPlanDaysFollowed: mealPlanDaysFollowed,
            workoutsLogged: workoutsLogged,
            trainingAlignmentScore: snapshot.trainingAlignmentScore
        )
    }
}

/// Static baseline + targets. See docs/HISTORICAL-DATA.md.
public struct HealthBaseline: Sendable {
    public let stepsPerDay: Double
    public let activeCalPerDay: Double
    public let restingHR: Double
    public let hrv: Double
    public let exerciseMinPerWeek: Double
    public let walkingHR: Double
    public let respiratoryRate: Double
    public let vo2Max: Double
    public let sleepHoursPerNight: Double
    public let weightLb: Double

    public static let p1Baseline = HealthBaseline(
        stepsPerDay: 7_800,
        activeCalPerDay: 640,
        restingHR: 66,
        hrv: 57,
        exerciseMinPerWeek: 50,
        walkingHR: 107,
        respiratoryRate: 15,
        vo2Max: 38,
        sleepHoursPerNight: 7.2,
        weightLb: 196
    )

    public static let target = HealthBaseline(
        stepsPerDay: 7_500,
        activeCalPerDay: 600,
        restingHR: 65,
        hrv: 60,
        exerciseMinPerWeek: 150,
        walkingHR: 110,
        respiratoryRate: 14,
        vo2Max: 45,
        sleepHoursPerNight: 8.0,
        weightLb: 205
    )

    public init(
        stepsPerDay: Double, activeCalPerDay: Double,
        restingHR: Double, hrv: Double,
        exerciseMinPerWeek: Double, walkingHR: Double,
        respiratoryRate: Double, vo2Max: Double,
        sleepHoursPerNight: Double, weightLb: Double
    ) {
        self.stepsPerDay = stepsPerDay
        self.activeCalPerDay = activeCalPerDay
        self.restingHR = restingHR
        self.hrv = hrv
        self.exerciseMinPerWeek = exerciseMinPerWeek
        self.walkingHR = walkingHR
        self.respiratoryRate = respiratoryRate
        self.vo2Max = vo2Max
        self.sleepHoursPerNight = sleepHoursPerNight
        self.weightLb = weightLb
    }
}

public struct BaselineComparison: Sendable, Codable, Hashable {
    public let metricName: String
    public let current: Double
    public let baseline: Double
    public let deltaPercent: Double

    public init(metricName: String, current: Double, baseline: Double) {
        self.metricName = metricName
        self.current = current
        self.baseline = baseline
        self.deltaPercent = baseline == 0 ? 0 : ((current - baseline) / baseline) * 100
    }
}
