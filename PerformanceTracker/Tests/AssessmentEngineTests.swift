import XCTest
import SwiftData
#if canImport(PerformanceTracker)
@testable import PerformanceTracker
#endif

@MainActor
final class AssessmentEngineTests: XCTestCase {

    func testSeedData_ProducesThreeAssessments() throws {
        let container = try ModelContainer(
            for: Assessment.self, HealthMetrics.self, ManualEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        SeedData.seedIfNeeded(context: context)

        let all = try context.fetch(FetchDescriptor<Assessment>())
        XCTAssertEqual(all.count, 3)

        let ids = Set(all.map(\.periodId))
        XCTAssertTrue(ids.contains("2026-W08-P1"))
        XCTAssertTrue(ids.contains("2026-W10-P2"))
        XCTAssertTrue(ids.contains("2026-W12-P3"))
    }

    func testSeedData_IsIdempotent() throws {
        let container = try ModelContainer(
            for: Assessment.self, HealthMetrics.self, ManualEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        SeedData.seedIfNeeded(context: context)
        SeedData.seedIfNeeded(context: context)

        let count = try context.fetch(FetchDescriptor<Assessment>()).count
        XCTAssertEqual(count, 3, "Seeding twice should not duplicate")
    }

    func testSeedData_TrajectoryMatchesExpected() throws {
        let container = try ModelContainer(
            for: Assessment.self, HealthMetrics.self, ManualEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        SeedData.seedIfNeeded(context: context)

        let descriptor = FetchDescriptor<Assessment>(
            sortBy: [SortDescriptor(\Assessment.periodStart, order: .forward)]
        )
        let seeded = try context.fetch(descriptor)
        XCTAssertEqual(seeded[0].overallGrade, .cPlus)
        XCTAssertEqual(seeded[1].overallGrade, .bPlus)
        XCTAssertEqual(seeded[2].overallGrade, .aMinus)
    }
}
