import SwiftUI
import SwiftData

public struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @State private var vm: DashboardViewModel?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    ringSection
                    partialNotice
                    if let vm {
                        FinanceCard(
                            snapshot: vm.abacusSnapshot,
                            isConnected: vm.abacusConnected,
                            lookbackDays: vm.financeLookbackDays,
                            onLookbackChange: { d in
                                vm.financeLookbackDays = d
                                Task { await vm.loadAbacusSnapshot() }
                            }
                        )
                    }
                    categoriesGrid
                    generateButton
                }
                .padding()
            }
            .navigationTitle("Performance")
            .background(Color.black.ignoresSafeArea())
            .refreshable {
                vm?.refresh()
                await vm?.loadAbacusSnapshot()
            }
        }
        .onAppear {
            if vm == nil { vm = DashboardViewModel(context: context) }
            vm?.refresh()
            Task { await vm?.loadAbacusSnapshot() }
        }
    }

    private var header: some View {
        HStack {
            // Period picker — tap to choose
            if let vm, !vm.allAssessments.isEmpty {
                Menu {
                    ForEach(vm.allAssessments, id: \.persistentModelID) { a in
                        Button {
                            vm.selectedAssessment = a
                        } label: {
                            HStack {
                                Text(a.periodId)
                                if a.persistentModelID == vm.selectedAssessment?.persistentModelID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(vm.selectedAssessment?.periodId ?? "—")
                            .font(.headline)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(Brand.softIris)
                }
            } else {
                Text("No assessments yet").font(.headline).foregroundStyle(.secondary)
            }
            Spacer()
            if let gen = vm?.selectedAssessment?.generatedAt {
                Text(gen, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var ringSection: some View {
        if let a = vm?.selectedAssessment {
            GradeRingView(grade: a.overallGrade, gpa: a.overallGPA)
                .padding(.vertical, 12)
        } else {
            GradeRingView(grade: .incomplete)
                .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var partialNotice: some View {
        if let a = vm?.selectedAssessment, !a.isComplete {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill").foregroundStyle(.yellow)
                Text("Partial assessment — Phase 2 categories (Product, Jobs, Time, Strategy) are not yet graded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var categoriesGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(GradeCategory.allCases, id: \.self) { cat in
                NavigationLink {
                    CategoryDetailView(
                        category: cat,
                        assessments: (vm?.allAssessments ?? []).reversed()
                    )
                } label: {
                    CategoryCardView(
                        category: cat,
                        grade: vm?.selectedAssessment?.grade(for: cat) ?? .incomplete,
                        trend: vm?.trend(for: cat) ?? []
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var generateButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await vm?.generateThisWeek() }
            } label: {
                HStack {
                    if vm?.isGenerating == true { ProgressView() }
                    Text(vm?.isGenerating == true ? "Generating…" : "Generate This Week")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Brand.softIris.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Brand.softIris)
            }
            .disabled(vm?.isGenerating == true)

            if let status = vm?.lastGenerateStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
