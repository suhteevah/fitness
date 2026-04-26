import Foundation

/// Macro totals for a meal or a day.
public struct MacroTotals: Codable, Sendable, Hashable {
    public var kcal: Int
    public var proteinG: Int
    public var fatG: Int
    public var carbG: Int

    public init(kcal: Int = 0, proteinG: Int = 0, fatG: Int = 0, carbG: Int = 0) {
        self.kcal = kcal
        self.proteinG = proteinG
        self.fatG = fatG
        self.carbG = carbG
    }

    public static func + (lhs: MacroTotals, rhs: MacroTotals) -> MacroTotals {
        MacroTotals(
            kcal: lhs.kcal + rhs.kcal,
            proteinG: lhs.proteinG + rhs.proteinG,
            fatG: lhs.fatG + rhs.fatG,
            carbG: lhs.carbG + rhs.carbG
        )
    }

    public static func - (lhs: MacroTotals, rhs: MacroTotals) -> MacroTotals {
        MacroTotals(
            kcal: lhs.kcal - rhs.kcal,
            proteinG: lhs.proteinG - rhs.proteinG,
            fatG: lhs.fatG - rhs.fatG,
            carbG: lhs.carbG - rhs.carbG
        )
    }
}

/// Context tag that pairs (training context, recovery state).
public struct MealContextTag: Codable, Sendable, Hashable {
    public enum Training: String, Codable, Sendable {
        case postStrength
        case postZone2
        case postZone4
        case restDay
        case preHardTomorrow
        case fallback
    }

    public let training: Training
    public let recovery: RecoveryScore

    public init(_ training: Training, _ recovery: RecoveryScore) {
        self.training = training
        self.recovery = recovery
    }
}

/// Time-of-day meal slot. Used to pick which meal in the day to recommend.
public enum MealSlot: String, Codable, Sendable, CaseIterable {
    case breakfast      // 5am – 11am
    case lunch          // 11am – 3pm
    case preWorkout     // 3pm – 5pm (optional, only if a hard session is planned tonight)
    case dinner         // 5pm – 9pm
    case lateSnack      // 9pm – 1am
    case earlyMorning   // 1am – 5am (only if Matt's actually awake)

    /// Pick the slot for the given Date in the current calendar.
    public static func current(now: Date = .now, calendar: Calendar = .current,
                               hasHardWorkoutTonight: Bool = false) -> MealSlot {
        let hour = calendar.component(.hour, from: now)
        switch hour {
        case 5..<11:                                  return .breakfast
        case 11..<15:                                 return .lunch
        case 15..<17 where hasHardWorkoutTonight:     return .preWorkout
        case 15..<17:                                 return .lunch          // late lunch if no hard session
        case 17..<21:                                 return .dinner
        case 21..<24, 0..<1:                          return .lateSnack
        default:                                       return .earlyMorning
        }
    }

    public var displayName: String {
        switch self {
        case .breakfast:    return "Breakfast"
        case .lunch:        return "Lunch"
        case .preWorkout:   return "Pre-Workout"
        case .dinner:       return "Dinner"
        case .lateSnack:    return "Late Snack"
        case .earlyMorning: return "Early Morning"
        }
    }

    /// Approximate expected kcal for this slot. Used to bias template selection.
    public var targetKcal: Int {
        switch self {
        case .breakfast:    return 500   // moderate, kickstart
        case .lunch:        return 600   // largest of day on a workout day
        case .preWorkout:   return 350   // small, fueling
        case .dinner:       return 600   // recovery-focused
        case .lateSnack:    return 250   // light
        case .earlyMorning: return 200   // very light if eaten at all
        }
    }

    /// Templates with kcal in this range are best fit for this slot.
    public var kcalRange: ClosedRange<Int> {
        let target = targetKcal
        return (target - 150) ... (target + 150)
    }
}

/// A single meal template. Loaded from `data/meal-plans/*.json` at runtime or
/// from compiled seed in `KetoAnimalTemplates`.
public struct MealTemplate: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let dietProfile: DietProfile
    public let macros: MacroTotals
    /// Contexts the template fits. A template may fit multiple (e.g. rest+good AND rest+poor).
    public let contexts: [MealContextTag]
    public let ingredients: [String]
    public let source: String?        // "seed", or a Matt plan id like "plan-1"
    public let isFallback: Bool       // last-resort pick when no context matches

    public init(
        id: String,
        name: String,
        dietProfile: DietProfile,
        macros: MacroTotals,
        contexts: [MealContextTag],
        ingredients: [String] = [],
        source: String? = "seed",
        isFallback: Bool = false
    ) {
        self.id = id
        self.name = name
        self.dietProfile = dietProfile
        self.macros = macros
        self.contexts = contexts
        self.ingredients = ingredients
        self.source = source
        self.isFallback = isFallback
    }
}
