import SwiftUI

struct CategorySummaryView: View {
    @Environment(WatchSessionManager.self) private var session

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("Categories").font(.headline)
                ForEach(GradeCategory.allCases, id: \.self) { cat in
                    HStack {
                        Image(systemName: cat.systemImageName).foregroundStyle(grade(for: cat).colorFamily.color)
                        Text(cat.shortName).font(.caption)
                        Spacer()
                        Text(grade(for: cat) == .incomplete ? "—" : grade(for: cat).rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(grade(for: cat).colorFamily.color)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
        }
    }

    private func grade(for cat: GradeCategory) -> Grade {
        session.latestPayload?.categoryGrades[cat] ?? .incomplete
    }
}
