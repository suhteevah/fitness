import SwiftUI

public struct AbacusSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var baseURL: String = "https://cnc-server.tailb85819.ts.net/abacus/api/v1"
    @State private var apiKey: String = ""
    @State private var primaryOrgId: String = ""
    @State private var orgs: [AbacusOrg] = []

    @State private var status: Status = .idle
    @State private var statusMessage: String = ""

    private enum Status { case idle, testing, ok, fail }

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Abacus is your private financial backend on the Tailscale mesh. Connection requires Tailscale active on this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Abacus")
                }

                Section("Server") {
                    TextField("Base URL", text: $baseURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("API Key (X-API-Key)", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if !orgs.isEmpty {
                    Section {
                        Picker("Organization", selection: $primaryOrgId) {
                            Text("All Organizations (combined)").tag("")
                            ForEach(orgs) { org in
                                Text(org.name).tag(org.id)
                            }
                        }
                    } header: {
                        Text("Scope (drives Revenue grade)")
                    } footer: {
                        Text("Pick \"All Organizations\" to grade revenue across every Abacus org you own. Pick a single org to focus on one business unit.")
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await testAndSave() }
                    } label: {
                        HStack {
                            if status == .testing { ProgressView().padding(.trailing, 6) }
                            Text(status == .testing ? "Testing…" : "Test & Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(status == .testing || baseURL.isEmpty || apiKey.isEmpty)

                    if status != .idle {
                        statusBanner
                    }
                }

                Section {
                    Button("Clear stored credentials", role: .destructive) {
                        AbacusCredentials.clear()
                        Task { await AbacusService.shared.configure(.init()) }
                        statusMessage = "Cleared"
                        status = .idle
                    }
                }
            }
            .navigationTitle("Abacus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                let cur = AbacusCredentials.loadSettings()
                if let u = cur.baseURL { baseURL = u.absoluteString }
                if let k = cur.apiKey { apiKey = k }
                if let o = cur.primaryOrgId { primaryOrgId = o }
                if cur.isConfigured {
                    await AbacusService.shared.configure(cur)
                    await loadOrgs()
                }
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        let color: Color = {
            switch status {
            case .ok: return Brand.seaGlassTeal
            case .fail: return Color(red: 0.882, green: 0.525, blue: 0.392)
            default: return Color.gray
            }
        }()
        let icon: String = {
            switch status {
            case .ok: return "checkmark.circle.fill"
            case .fail: return "exclamationmark.triangle.fill"
            default: return "info.circle"
            }
        }()
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            Text(statusMessage).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func testAndSave() async {
        status = .testing
        statusMessage = "Reaching CNC over Tailscale…"

        guard let url = URL(string: baseURL.trimmingCharacters(in: .whitespaces)) else {
            status = .fail
            statusMessage = "Invalid base URL"
            return
        }

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)

        // Try a live ping with the new creds before persisting.
        await AbacusService.shared.configure(.init(baseURL: url, apiKey: trimmedKey, primaryOrgId: primaryOrgId.isEmpty ? nil : primaryOrgId))
        do {
            let h = try await AbacusService.shared.health()
            statusMessage = "Connected · \(h.dbTransactionsCount ?? 0) transactions · last import \(h.lastImport ?? "—")"
            status = .ok

            // Persist
            AbacusCredentials.saveBaseURL(url)
            AbacusCredentials.saveAPIKey(trimmedKey)

            // Load orgs for picker
            await loadOrgs()
        } catch let AbacusService.AbacusError.http(code, body) {
            status = .fail
            statusMessage = "HTTP \(code) — \(body.prefix(120))"
        } catch let AbacusService.AbacusError.unreachable(msg) {
            status = .fail
            statusMessage = "Unreachable — \(msg). Is Tailscale active?"
        } catch {
            status = .fail
            statusMessage = "\(error)"
        }
    }

    private func loadOrgs() async {
        do {
            orgs = try await AbacusService.shared.orgs()
            // Don't auto-pick the first org — empty primaryOrgId means "All Organizations
            // (combined)" which is the right default for whole-picture revenue grading.
            AbacusCredentials.savePrimaryOrgId(primaryOrgId.isEmpty ? nil : primaryOrgId)
        } catch {
            Log.assessment.error("Loading orgs failed: \(error)")
        }
    }
}
