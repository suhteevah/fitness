import Foundation
import SwiftData
import Observation

@Observable
@MainActor
public final class DashboardViewModel {
    public var selectedAssessment: Assessment?
    public var allAssessments: [Assessment] = []
    public var isGenerating: Bool = false

    // Abacus snapshot — populated lazily so dashboard reflects live finance.
    public var abacusSnapshot: AbacusSnapshot?
    public var abacusConnected: Bool = false

    private let context: ModelContext
    private let engine: AssessmentEngine

    public init(context: ModelContext) {
        self.context = context
        self.engine = AssessmentEngine(context: context)
    }

    /// Lookback window (in days) for the dashboard finance card. Wider than the
    /// 7-day grading window so the transaction log surfaces real history even
    /// when no revenue landed in the current ISO week. Grading is unaffected —
    /// `AssessmentEngine` queries Abacus with the assessment's own period range.
    public var financeLookbackDays: Int = 30

    public func loadAbacusSnapshot() async {
        let settings = AbacusCredentials.loadSettings()
        abacusConnected = settings.isConfigured
        guard settings.isConfigured else { abacusSnapshot = nil; return }
        let now = Date.now
        let end = now
        let start = Calendar.current.date(byAdding: .day, value: -financeLookbackDays, to: now) ?? now
        abacusSnapshot = await AbacusService.shared.fetchWeeklySnapshot(periodStart: start, periodEnd: end)
        Log.viewModel.info("Abacus snapshot loaded: lookback=\(self.financeLookbackDays)d rev=\(self.abacusSnapshot?.totalRevenueWeek ?? 0) entries=\(self.abacusSnapshot?.revenueEntries.count ?? 0)")
    }

    public func refresh() {
        let descriptor = FetchDescriptor<Assessment>(
            sortBy: [SortDescriptor(\Assessment.periodStart, order: .reverse)]
        )
        do {
            allAssessments = try context.fetch(descriptor)
            if selectedAssessment == nil { selectedAssessment = allAssessments.first }
            Log.viewModel.info("Dashboard loaded \(self.allAssessments.count) assessments")
        } catch {
            Log.viewModel.error("Dashboard refresh failed: \(error.localizedDescription)")
        }
    }

    /// Last status of a generation run, surfaced in UI so the user sees something.
    public var lastGenerateStatus: String? = nil

    public func generateThisWeek() async {
        isGenerating = true
        lastGenerateStatus = nil
        defer { isGenerating = false }

        let now = Date.now
        let start = now.startOfISOWeek()
        let end = now.endOfISOWeek()
        let id = now.isoPeriodId

        // If an assessment already exists for this period, delete it (re-run replaces).
        let existing = (try? context.fetch(
            FetchDescriptor<Assessment>(predicate: #Predicate { $0.periodId == id })
        )) ?? []
        for a in existing { context.delete(a) }
        try? context.save()

        let assessment = await engine.runAssessment(for: (start: start, end: end, id: id))
        Log.viewModel.info("Generated assessment \(id): overall=\(assessment.overallGrade.rawValue) complete=\(assessment.isComplete)")

        refresh()
        // Auto-select the just-generated assessment so the user sees it.
        if let fresh = allAssessments.first(where: { $0.periodId == id }) {
            selectedAssessment = fresh
        }

        let statusGrade = assessment.overallGrade == .incomplete ? "Incomplete" : assessment.overallGrade.rawValue
        let dataNote = assessment.isComplete ? "complete" : "partial — Phase 2 categories pending"
        lastGenerateStatus = "Generated \(id) — \(statusGrade) (\(dataNote))"
    }

    /// Trend history (oldest → newest) for a category across all stored assessments.
    public func trend(for category: GradeCategory) -> [Grade] {
        allAssessments
            .sorted { $0.periodStart < $1.periodStart }
            .map { $0.grade(for: category) }
    }
}
