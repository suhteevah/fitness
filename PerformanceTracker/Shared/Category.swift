import Foundation

/// The 7 assessment categories. Weights sum to 1.0.
/// Source of truth: docs/GRADING-RUBRIC.md
///
/// Named `GradeCategory` (not `Category`) to avoid collision with the objc
/// `Category` typedef from `<objc/runtime.h>`, which interferes with Swift
/// type-lookup when this enum is referenced from XCTest contexts.
public enum GradeCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case productDevelopment
    case revenuePipeline
    case jobHunting
    case clientWork
    case physicalHealth
    case timeManagement
    case strategyDecisions

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .productDevelopment: return "Product Development"
        case .revenuePipeline:    return "Revenue & Pipeline"
        case .jobHunting:         return "Job Hunting"
        case .clientWork:         return "Client Work"
        case .physicalHealth:     return "Physical Health"
        case .timeManagement:     return "Time Management"
        case .strategyDecisions:  return "Strategy"
        }
    }

    public var shortName: String {
        switch self {
        case .productDevelopment: return "Product"
        case .revenuePipeline:    return "Revenue"
        case .jobHunting:         return "Jobs"
        case .clientWork:         return "Clients"
        case .physicalHealth:     return "Health"
        case .timeManagement:     return "Time"
        case .strategyDecisions:  return "Strategy"
        }
    }

    public var weight: Double {
        switch self {
        case .productDevelopment: return 0.25
        case .revenuePipeline:    return 0.20
        case .jobHunting:         return 0.15
        case .clientWork:         return 0.15
        case .physicalHealth:     return 0.10
        case .timeManagement:     return 0.10
        case .strategyDecisions:  return 0.05
        }
    }

    public var systemImageName: String {
        switch self {
        case .productDevelopment: return "hammer.fill"
        case .revenuePipeline:    return "dollarsign.circle.fill"
        case .jobHunting:         return "briefcase.fill"
        case .clientWork:         return "person.2.fill"
        case .physicalHealth:     return "heart.fill"
        case .timeManagement:     return "calendar"
        case .strategyDecisions:  return "brain.head.profile"
        }
    }

    /// Whether this category is supported in Phase 1 MVP.
    public var isPhase1: Bool {
        switch self {
        case .physicalHealth, .revenuePipeline, .clientWork: return true
        default: return false
        }
    }
}

/// Named source that contributed to an assessment.
public enum DataSource: String, Codable, Sendable {
    case healthKit
    case gmail
    case github
    case googleCalendar
    case manualEntry
    case claudeConversations
}
