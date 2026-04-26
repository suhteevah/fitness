import SwiftUI

@main
struct PerformanceTrackerWatchApp: App {
    @State private var session = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(session)
                .onAppear { session.activate() }
        }
    }
}

struct WatchRootView: View {
    @Environment(WatchSessionManager.self) private var session

    var body: some View {
        TabView {
            GradeRingWatchView()
                .tag(0)
            HealthQuickView()
                .tag(1)
            QuickActionsView()
                .tag(2)
            CategorySummaryView()
                .tag(3)
        }
        .tabViewStyle(.verticalPage)
    }
}
