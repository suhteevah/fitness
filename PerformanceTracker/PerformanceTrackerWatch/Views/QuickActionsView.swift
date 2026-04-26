import SwiftUI

struct QuickActionsView: View {
    @Environment(WatchSessionManager.self) private var session
    @State private var justLogged: String?

    var body: some View {
        VStack(spacing: 8) {
            Text("Quick Log").font(.headline)
            Button { log(.walk, detail: "20 min") } label: {
                Label("Walk", systemImage: "figure.walk")
                    .frame(maxWidth: .infinity)
            }
            Button { log(.mealPlanFollowed) } label: {
                Label("Meal Plan ✓", systemImage: "leaf.fill")
                    .frame(maxWidth: .infinity)
            }
            Button { log(.workout, detail: "strength") } label: {
                Label("Workout", systemImage: "dumbbell.fill")
                    .frame(maxWidth: .infinity)
            }
            if let j = justLogged {
                Text("Logged \(j)").font(.caption2).foregroundStyle(.green)
            }
        }
        .padding()
        .buttonStyle(.bordered)
    }

    private func log(_ kind: WatchMessage.QuickLog.Kind, detail: String? = nil) {
        session.sendQuickLog(.init(kind: kind, detail: detail))
        justLogged = kind.rawValue
    }
}
