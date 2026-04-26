import Foundation

/// Diet profile — pluggable; only `.ketoAnimalBasedNoPork` is implemented for Phase 1.
public enum DietProfile: String, Codable, Sendable {
    case ketoAnimalBasedNoPork
    case normal   // future
}

/// Kind of training session. Drives intensity factor for TRIMP and meal context.
public enum WorkoutKind: String, Codable, Sendable, CaseIterable {
    case walk
    case zone2
    case zone4
    case strength
    case mobility
    case sport
    case rest

    public var displayName: String {
        switch self {
        case .walk: return "Walk"
        case .zone2: return "Zone 2 Cardio"
        case .zone4: return "Zone 4 / High-Intensity"
        case .strength: return "Strength"
        case .mobility: return "Mobility / Stretch"
        case .sport: return "Sport / Hike"
        case .rest: return "Rest"
        }
    }

    /// Banister intensity factor (0–1) used in TRIMP when avg HR unavailable.
    public var intensityFactor: Double {
        switch self {
        case .walk: return 0.25
        case .zone2: return 0.55
        case .zone4: return 0.90
        case .strength: return 0.75
        case .mobility: return 0.15
        case .sport: return 0.60
        case .rest: return 0.0
        }
    }
}

/// A single workout session. Sendable — crosses actor boundaries safely.
public struct WorkoutProfile: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let kind: WorkoutKind
    public let durationMin: Int
    public let rpe: Int?
    public let avgHR: Int?
    public let estKcal: Int?
    public let date: Date
    public let notes: String?

    public init(
        id: UUID = UUID(),
        kind: WorkoutKind,
        durationMin: Int,
        rpe: Int? = nil,
        avgHR: Int? = nil,
        estKcal: Int? = nil,
        date: Date = .now,
        notes: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.durationMin = durationMin
        self.rpe = rpe
        self.avgHR = avgHR
        self.estKcal = estKcal
        self.date = date
        self.notes = notes
    }
}

/// Recovery classification synthesized from HRV, sleep, resting HR trends.
public enum RecoveryScore: String, Codable, Sendable {
    case good      // ≥ 0.7 on 0-1 recovery index
    case moderate  // 0.4–0.7
    case poor      // < 0.4

    public static func classify(hrvNormalized: Double, sleepNormalized: Double, rhrNormalized: Double) -> RecoveryScore {
        let score = 0.4 * hrvNormalized + 0.4 * sleepNormalized + 0.2 * rhrNormalized
        switch score {
        case 0.7...: return .good
        case 0.4..<0.7: return .moderate
        default: return .poor
        }
    }
}

/// Matt's physiological constants — used by TRIMP HR reserve calc.
public enum MattPhysiology {
    public static let restingHRBaseline: Double = 63
    public static let maxHREstimated: Double = 183   // 220 - age 37
    public static let weightLb: Double = 196
    public static let tdeeKcal: Double = 2_840
    public static let muscleGainTargetKcal: Double = 2_200  // slight deficit, muscle retention
    public static let zone2LowHR: Int = 114
    public static let zone2HighHR: Int = 133
}
