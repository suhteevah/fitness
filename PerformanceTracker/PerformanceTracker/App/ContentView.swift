import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }

            HealthDashboardView()
                .tabItem { Label("Health", systemImage: "heart.fill") }

            RevenueView()
                .tabItem { Label("Revenue", systemImage: "dollarsign.circle.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Brand.softIris)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Assessment.self, HealthMetrics.self, ManualEntry.self, EatenMealLog.self, MealPrepBatch.self])
}
