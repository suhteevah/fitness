import Foundation

/// Messages exchanged between iPhone and Apple Watch via WatchConnectivity.
public enum WatchMessage: Codable, Sendable {
    case requestLatestAssessment
    case assessmentPayload(AssessmentPayload)
    case quickLog(QuickLog)
    case ack

    /// Minimal subset of assessment data sent to Watch.
    public struct AssessmentPayload: Codable, Sendable {
        public let periodId: String
        public let overallGrade: Grade
        public let overallGPA: Double
        public let categoryGrades: [GradeCategory: Grade]
        public let stepsToday: Int?
        public let hrvLatest: Double?
        public let restingHRLatest: Double?
        public let generatedAt: Date

        public init(
            periodId: String,
            overallGrade: Grade,
            overallGPA: Double,
            categoryGrades: [GradeCategory: Grade],
            stepsToday: Int?,
            hrvLatest: Double?,
            restingHRLatest: Double?,
            generatedAt: Date
        ) {
            self.periodId = periodId
            self.overallGrade = overallGrade
            self.overallGPA = overallGPA
            self.categoryGrades = categoryGrades
            self.stepsToday = stepsToday
            self.hrvLatest = hrvLatest
            self.restingHRLatest = restingHRLatest
            self.generatedAt = generatedAt
        }
    }

    public struct QuickLog: Codable, Sendable {
        public enum Kind: String, Codable, Sendable {
            case walk, mealPlanFollowed, workout
        }
        public let kind: Kind
        public let date: Date
        public let detail: String?

        public init(kind: Kind, date: Date = .now, detail: String? = nil) {
            self.kind = kind
            self.date = date
            self.detail = detail
        }
    }
}
