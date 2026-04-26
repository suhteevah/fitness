import Foundation
import SwiftData

/// A completed weekly (or multi-week) performance assessment.
/// Persisted to SwiftData. Values also seeded from docs/HISTORICAL-DATA.md on first launch.
///
/// IMPORTANT: SwiftData on iOS 26 traps an internal assertion when reading
/// `[String: String]` dictionaries as stored @Model properties. We work around
/// this by storing structured data as JSON strings and decoding lazily.
/// Same precaution applied to the [String] arrays.
@Model
public final class Assessment {
    @Attribute(.unique) public var periodId: String      // e.g. "2026-W17"
    public var periodStart: Date
    public var periodEnd: Date

    // Overall
    public var overallGradeRaw: String                   // Grade.rawValue
    public var overallGPA: Double
    public var isComplete: Bool                          // all 7 categories graded

    // Per-category grades stored as JSON to dodge SwiftData dictionary issues.
    public var categoryGradesJSON: String

    // Optional narrative
    public var notes: String
    public var recommendationsJSON: String
    public var dataSourcesJSON: String

    // Relationships
    @Relationship(deleteRule: .cascade) public var healthMetrics: HealthMetrics?

    public var generatedAt: Date

    public init(
        periodId: String,
        periodStart: Date,
        periodEnd: Date,
        overallGrade: Grade,
        overallGPA: Double,
        categoryGrades: [GradeCategory: Grade],
        healthMetrics: HealthMetrics? = nil,
        isComplete: Bool = false,
        notes: String = "",
        recommendations: [String] = [],
        dataSources: [DataSource] = [],
        generatedAt: Date = .now
    ) {
        self.periodId = periodId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.overallGradeRaw = overallGrade.rawValue
        self.overallGPA = overallGPA
        self.isComplete = isComplete
        self.notes = notes

        // Encode collections as JSON strings — bypasses SwiftData dict/array reading bug.
        var rawDict: [String: String] = [:]
        for (cat, grade) in categoryGrades { rawDict[cat.rawValue] = grade.rawValue }
        self.categoryGradesJSON = (try? Self.encodeJSON(rawDict)) ?? "{}"
        self.recommendationsJSON = (try? Self.encodeJSON(recommendations)) ?? "[]"
        self.dataSourcesJSON = (try? Self.encodeJSON(dataSources.map(\.rawValue))) ?? "[]"

        self.healthMetrics = healthMetrics
        self.generatedAt = generatedAt
    }

    public var overallGrade: Grade {
        Grade(rawValue: overallGradeRaw) ?? .incomplete
    }

    public var categoryGrades: [GradeCategory: Grade] {
        let raw: [String: String] = (try? Self.decodeJSON(categoryGradesJSON)) ?? [:]
        var out: [GradeCategory: Grade] = [:]
        for (catRaw, gradeRaw) in raw {
            if let c = GradeCategory(rawValue: catRaw), let g = Grade(rawValue: gradeRaw) {
                out[c] = g
            }
        }
        return out
    }

    public var recommendations: [String] {
        (try? Self.decodeJSON(recommendationsJSON)) ?? []
    }

    public var dataSources: [DataSource] {
        let raw: [String] = (try? Self.decodeJSON(dataSourcesJSON)) ?? []
        return raw.compactMap { DataSource(rawValue: $0) }
    }

    public func grade(for category: GradeCategory) -> Grade {
        categoryGrades[category] ?? .incomplete
    }

    // MARK: - JSON helpers

    private static func encodeJSON<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func decodeJSON<T: Decodable>(_ string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw NSError(domain: "Assessment", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// Comparison against the prior assessment.
public struct PeriodComparison: Sendable, Codable {
    public let from: String  // periodId
    public let to: String
    public let overallChange: GradeChange
    public let categoryChanges: [GradeCategory: GradeChange]

    public init(from: String, to: String, overallChange: GradeChange, categoryChanges: [GradeCategory: GradeChange]) {
        self.from = from
        self.to = to
        self.overallChange = overallChange
        self.categoryChanges = categoryChanges
    }
}
