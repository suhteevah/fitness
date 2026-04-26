import SwiftUI
import HealthKit

public struct SettingsView: View {
    @State private var healthAuthStatus: String = "Unknown"
    @State private var abacusConfigured: Bool = false
    @State private var showAbacusSheet: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("HealthKit") {
                    HStack {
                        Text("Authorization status")
                        Spacer()
                        Text(healthAuthStatus).foregroundStyle(.secondary)
                    }
                    Button("Re-request access") {
                        Task { await requestAccess() }
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "PerformanceTracker")
                    LabeledContent("Phase", value: "1 (MVP)")
                    LabeledContent("Owner", value: "Matt Gates · Ridge Cell Repair LLC")
                    LabeledContent("Bundle", value: "com.ridgecellrepair.performancetracker")
                }

                Section("Abacus (Financial)") {
                    HStack {
                        Image(systemName: abacusConfigured ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(abacusConfigured ? Brand.seaGlassTeal : .secondary)
                        Text(abacusConfigured ? "Connected (Tailscale)" : "Not connected")
                        Spacer()
                    }
                    Button("Connect Abacus") { showAbacusSheet = true }
                }

                Section("Coming in Phase 2") {
                    Text("Gmail OAuth — job application scanning")
                    Text("GitHub PAT — code activity tracking")
                    Text("Google Calendar — time management signals")
                    Text("Watch complication")
                }
            }
            .navigationTitle("Settings")
            .task { updateStatus(); refreshAbacusState() }
            .sheet(isPresented: $showAbacusSheet, onDismiss: { refreshAbacusState() }) {
                AbacusSettingsView()
            }
        }
    }

    private func refreshAbacusState() {
        abacusConfigured = AbacusCredentials.loadSettings().isConfigured
    }

    private func updateStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthAuthStatus = "Not available"
            return
        }
        // We can't directly read authorizationStatus without a type; pick one representative.
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let status = HKHealthStore().authorizationStatus(for: stepType)
            switch status {
            case .notDetermined: healthAuthStatus = "Not determined"
            case .sharingDenied: healthAuthStatus = "Denied"
            case .sharingAuthorized: healthAuthStatus = "Authorized"
            @unknown default: healthAuthStatus = "Unknown"
            }
        }
    }

    private func requestAccess() async {
        do {
            try await HealthKitService.shared.requestAuthorization()
            updateStatus()
        } catch {
            Log.healthKit.error("Settings re-request failed: \(error.localizedDescription)")
        }
    }
}
