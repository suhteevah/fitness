import Foundation
import SwiftUI

/// Letter grade with GPA conversion. Source of truth: docs/GRADING-RUBRIC.md
public enum Grade: String, Codable, CaseIterable, Sendable {
    case aPlus = "A+"
    case a = "A"
    case aMinus = "A-"
    case bPlus = "B+"
    case b = "B"
    case bMinus = "B-"
    case cPlus = "C+"
    case c = "C"
    case cMinus = "C-"
    case dPlus = "D+"
    case d = "D"
    case dMinus = "D-"
    case f = "F"
    case incomplete = "I"

    /// GPA on 4.3 scale. `.incomplete` returns nil (excluded from averages).
    public var gpa: Double? {
        switch self {
        case .aPlus: return 4.3
        case .a: return 4.0
        case .aMinus: return 3.7
        case .bPlus: return 3.3
        case .b: return 3.0
        case .bMinus: return 2.7
        case .cPlus: return 2.3
        case .c: return 2.0
        case .cMinus: return 1.7
        case .dPlus: return 1.3
        case .d: return 1.0
        case .dMinus: return 0.7
        case .f: return 0.0
        case .incomplete: return nil
        }
    }

    /// Convert a raw score (0 ... maxScore) into a letter grade.
    /// Thresholds defined in docs/GRADING-RUBRIC.md.
    public static func fromScore(_ score: Double, maxScore: Double) -> Grade {
        let normalized = (score / maxScore) * 4.3
        switch normalized {
        case 4.1...:  return .aPlus
        case 3.85...: return .a
        case 3.55...: return .aMinus
        case 3.2...:  return .bPlus
        case 2.85...: return .b
        case 2.55...: return .bMinus
        case 2.2...:  return .cPlus
        case 1.85...: return .c
        case 1.55...: return .cMinus
        case 1.15...: return .dPlus
        case 0.85...: return .d
        case 0.5...:  return .dMinus
        default:      return .f
        }
    }

    /// Convert weighted-average GPA back into a letter grade.
    public static func fromGPA(_ gpa: Double) -> Grade {
        switch gpa {
        case 4.15...: return .aPlus
        case 3.85...: return .a
        case 3.5...:  return .aMinus
        case 3.15...: return .bPlus
        case 2.85...: return .b
        case 2.5...:  return .bMinus
        case 2.15...: return .cPlus
        case 1.85...: return .c
        case 1.5...:  return .cMinus
        case 1.15...: return .dPlus
        case 0.85...: return .d
        case 0.5...:  return .dMinus
        default:      return .f
        }
    }

    /// Color family for UI. Dark-mode-first.
    /// Source of truth: docs/DESIGN-SYSTEM.md
    public var colorFamily: GradeColorFamily {
        switch self {
        case .aPlus, .a, .aMinus: return .honeyGold       // celebration
        case .bPlus, .b, .bMinus: return .seaGlassTeal    // calm positive
        case .cPlus, .c, .cMinus: return .softAmber       // neutral warning
        case .dPlus, .d, .dMinus: return .warmCoral       // concern
        case .f: return .deepRed                          // crisis
        case .incomplete: return .coolGray                // neutral placeholder
        }
    }
}

/// Brand palette — see docs/DESIGN-SYSTEM.md
public enum Brand {
    /// Primary identity: Soft Iris. HSL(250°, 41%, 64%). Dark-mode-first.
    public static let softIris      = Color(red: 0.545, green: 0.498, blue: 0.788)  // #8B7FC9
    /// Warm accent: Honey Gold.
    public static let honeyGold     = Color(red: 0.886, green: 0.714, blue: 0.341)  // #E2B657
    /// Cool accent: Sea Glass Teal.
    public static let seaGlassTeal  = Color(red: 0.396, green: 0.769, blue: 0.722)  // #65C4B8
}

public enum GradeColorFamily: Sendable {
    case honeyGold, seaGlassTeal, softAmber, warmCoral, deepRed, coolGray

    public var color: Color {
        switch self {
        case .honeyGold:     return Color(red: 0.886, green: 0.714, blue: 0.341)  // #E2B657
        case .seaGlassTeal:  return Color(red: 0.396, green: 0.769, blue: 0.722)  // #65C4B8
        case .softAmber:     return Color(red: 0.878, green: 0.647, blue: 0.345)  // #E0A558
        case .warmCoral:     return Color(red: 0.882, green: 0.525, blue: 0.392)  // #E18664
        case .deepRed:       return Color(red: 0.769, green: 0.302, blue: 0.302)  // #C44D4D
        case .coolGray:      return Color(red: 0.541, green: 0.541, blue: 0.584)  // #8A8A95
        }
    }
}

/// Change in grade between two periods.
public struct GradeChange: Codable, Sendable, Hashable {
    public let from: Grade
    public let to: Grade

    public var direction: Direction {
        guard let fromGPA = from.gpa, let toGPA = to.gpa else { return .flat }
        if toGPA > fromGPA { return .up }
        if toGPA < fromGPA { return .down }
        return .flat
    }

    public enum Direction: Sendable { case up, down, flat }

    public init(from: Grade, to: Grade) {
        self.from = from
        self.to = to
    }
}
