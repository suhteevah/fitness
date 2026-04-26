import Foundation

/// Top-level daily health JSON (schema: `health-daily.v1`).
/// Produced by the 11pm Claude routine. See docs/DAILY-DATA-ROUTINE.md.
public struct HealthDaily: Codable, Sendable, Identifiable {
    public let schema: String
    public let date: String            // "YYYY-MM-DD"
    public let capturedAt: Date
    public let source: String
    public let health: HealthBody?
    public let notes: String?

    public var id: String { date }

    enum CodingKeys: String, CodingKey {
        case schema, date, source, notes, health
        case capturedAt = "captured_at"
    }
}

public struct HealthBody: Codable, Sendable {
    public let steps: Int?
    public let activeKcal: Int?
    public let basalKcal: Int?
    public let restingHRBpm: Int?
    public let hrvSDNNms: Double?
    public let exerciseMin: Int?
    public let walkingHRBpm: Int?
    public let respiratoryRateBpm: Double?
    public let bloodO2Pct: Int?
    public let vo2MaxMlKgMin: Double?
    public let weightLb: Double?
    public let sleep: SleepBody?
    public let workouts: [WorkoutLog]?
    public let mealsLogged: [MealLog]?

    enum CodingKeys: String, CodingKey {
        case steps, sleep, workouts
        case activeKcal = "active_kcal"
        case basalKcal = "basal_kcal"
        case restingHRBpm = "resting_hr_bpm"
        case hrvSDNNms = "hrv_sdnn_ms"
        case exerciseMin = "exercise_min"
        case walkingHRBpm = "walking_hr_bpm"
        case respiratoryRateBpm = "respiratory_rate_bpm"
        case bloodO2Pct = "blood_o2_pct"
        case vo2MaxMlKgMin = "vo2max_ml_kg_min"
        case weightLb = "weight_lb"
        case mealsLogged = "meals_logged"
    }
}

public struct SleepBody: Codable, Sendable {
    public let durationHours: Double?
    public let bedtime: Date?
    public let wakeTime: Date?
    public let stages: SleepStages?

    enum CodingKeys: String, CodingKey {
        case bedtime, stages
        case durationHours = "duration_hours"
        case wakeTime = "wake_time"
    }
}

public struct SleepStages: Codable, Sendable {
    public let awakeMin: Int?
    public let coreMin: Int?
    public let deepMin: Int?
    public let remMin: Int?

    enum CodingKeys: String, CodingKey {
        case awakeMin = "awake_min"
        case coreMin = "core_min"
        case deepMin = "deep_min"
        case remMin = "rem_min"
    }
}

public struct WorkoutLog: Codable, Sendable {
    public let kind: String
    public let durationMin: Int
    public let avgHRBpm: Int?
    public let estKcal: Int?
    public let startTime: Date?
    public let notes: String?

    enum CodingKeys: String, CodingKey {
        case kind, notes
        case durationMin = "duration_min"
        case avgHRBpm = "avg_hr_bpm"
        case estKcal = "est_kcal"
        case startTime = "start_time"
    }
}

public struct MealLog: Codable, Sendable {
    public let name: String
    public let kcal: Int?
    public let proteinG: Int?
    public let fatG: Int?
    public let carbG: Int?
    public let time: Date?
    public let matchedTemplateId: String?

    enum CodingKeys: String, CodingKey {
        case name, kcal, time
        case proteinG = "protein_g"
        case fatG = "fat_g"
        case carbG = "carb_g"
        case matchedTemplateId = "matched_template_id"
    }
}
