import SwiftUI
import SwiftData
import Charts

public struct CategoryDetailView: View {
    public let category: GradeCategory
    public let assessments: [Assessment]   // oldest → newest

    public init(category: GradeCategory, assessments: [Assessment]) {
        self.category = category
        self.assessments = assessments
    }

    private var trend: [(periodId: String, gpa: Double)] {
        assessments.compactMap { a in
            guard let gpa = a.grade(for: category).gpa else { return nil }
            return (a.periodId, gpa)
        }
    }

    private var latestGrade: Grade {
        assessments.last?.grade(for: category) ?? .incomplete
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                gradeCard
                trendChart
                weightCard
                criteriaCard
            }
            .padding()
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Image(systemName: category.systemImageName)
                .foregroundStyle(latestGrade.colorFamily.color)
                .font(.title2)
            Text(category.displayName).font(.title2.weight(.bold))
            Spacer()
        }
    }

    private var gradeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest grade").font(.caption).foregroundStyle(.secondary)
            Text(latestGrade == .incomplete ? "—" : latestGrade.rawValue)
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(latestGrade.colorFamily.color)
            if let gpa = latestGrade.gpa {
                Text(String(format: "%.2f GPA", gpa))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var trendChart: some View {
        if trend.count >= 2 {
            VStack(alignment: .leading, spacing: 8) {
                Text("Trajectory").font(.headline)
                Chart {
                    ForEach(Array(trend.enumerated()), id: \.offset) { idx, point in
                        LineMark(
                            x: .value("Period", point.periodId),
                            y: .value("GPA", point.gpa)
                        )
                        .foregroundStyle(latestGrade.colorFamily.color)
                        .symbol(.circle)
                    }
                }
                .chartYScale(domain: 0...4.3)
                .frame(height: 180)
            }
            .padding()
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var weightCard: some View {
        HStack {
            Image(systemName: "scalemass").foregroundStyle(.secondary)
            Text("Category weight").font(.subheadline)
            Spacer()
            Text("\(Int(category.weight * 100))% of overall grade")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    private var criteriaCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How this is graded").font(.headline)
            Text(criteriaText)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    private var criteriaText: String {
        switch category {
        case .productDevelopment:
            return "Code output, project scope, technical ambition. A+ for 10K+ lines or major launch. Source: project-status JSON harvested from your repos."
        case .revenuePipeline:
            return "Money received, invoices sent, pipeline value. A for $2,000+ received or multiple paying clients. Source: manual entry now; Abacus integration coming."
        case .jobHunting:
            return "Applications submitted, fit, interview callbacks, offers. Source: Gmail (Phase 2)."
        case .clientWork:
            return "Deliverables shipped, communications, invoices. A for multiple deliverables + invoiced. Source: manual entry + project status."
        case .physicalHealth:
            return "12 signals: HRV, RHR, sleep duration/consistency/stages, steps, exercise, meal plan, respiratory rate, VO2max, weight trend, training-recovery alignment. Source: HealthKit + 11pm Claude routine + manual entry."
        case .timeManagement:
            return "Calendar usage, project focus vs scatter, recreation during crisis. Source: Google Calendar (Phase 2)."
        case .strategyDecisions:
            return "Resource allocation, correct pivots, business-owner thinking. Qualitative; defaults to B once project status is available."
        }
    }
}
