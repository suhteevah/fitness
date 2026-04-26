import SwiftUI
import SwiftData

public struct RevenueView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ManualEntry.date, order: .reverse) private var allEntries: [ManualEntry]

    @State private var showAdd = false
    @State private var amount: String = ""
    @State private var client: String = ""
    @State private var source: String = "direct"

    @State private var abacusSnapshot: AbacusSnapshot?
    @State private var abacusConnected: Bool = false
    @State private var lookbackDays: Int = 30
    @State private var loading: Bool = false

    public init() {}

    private var revenueEntries: [ManualEntry] {
        allEntries.filter { $0.entryKind == .revenue }
    }

    /// Combined revenue (Abacus + manual) inside the lookback window.
    private var windowedTotal: Double {
        let abacusTotal = abacusSnapshot?.totalRevenueWeek ?? 0
        let cutoff = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: .now) ?? .now
        let manualTotal = revenueEntries
            .filter { $0.date >= cutoff }
            .compactMap(\.amountUSD)
            .reduce(0, +)
        return abacusTotal + manualTotal
    }

    public var body: some View {
        NavigationStack {
            List {
                summarySection
                lookbackSection
                if abacusConnected {
                    abacusSection
                }
                manualSection
            }
            .navigationTitle("Revenue")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await loadAbacus() }
                    } label: {
                        if loading { ProgressView() } else { Image(systemName: "arrow.clockwise") }
                    }
                }
            }
            .refreshable { await loadAbacus() }
            .sheet(isPresented: $showAdd) { addRevenueSheet }
            .task { await loadAbacus() }
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Last \(lookbackDays) days").font(.caption).foregroundStyle(.secondary)
                Text(windowedTotal, format: .currency(code: "USD"))
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Brand.honeyGold)
                if abacusConnected, let s = abacusSnapshot {
                    Text("\(s.revenueEntries.count) Abacus + \(manualInWindowCount) manual")
                        .font(.caption2).foregroundStyle(.secondary)
                } else if !abacusConnected {
                    Text("Manual-only — connect Abacus in Settings for bank feed")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var manualInWindowCount: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: .now) ?? .now
        return revenueEntries.filter { $0.date >= cutoff }.count
    }

    private var lookbackSection: some View {
        Section {
            Picker("Window", selection: $lookbackDays) {
                Text("7 days").tag(7)
                Text("30 days").tag(30)
                Text("90 days").tag(90)
                Text("1 year").tag(365)
            }
            .pickerStyle(.segmented)
            .onChange(of: lookbackDays) { _, _ in
                Task { await loadAbacus() }
            }
        }
    }

    @ViewBuilder
    private var abacusSection: some View {
        if let s = abacusSnapshot, !s.revenueEntries.isEmpty {
            Section("Abacus (bank feed)") {
                ForEach(s.revenueEntries.sorted(by: { $0.date > $1.date })) { e in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(e.clientName ?? e.source ?? "—")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(e.amountUSD, format: .currency(code: "USD"))
                                .fontWeight(.semibold).foregroundStyle(Brand.honeyGold)
                        }
                        HStack {
                            Text(e.date).font(.caption).foregroundStyle(.secondary)
                            if let memo = e.memo, !memo.isEmpty {
                                Text("·").font(.caption).foregroundStyle(.secondary)
                                Text(memo).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                }
            }
        } else if abacusSnapshot != nil {
            Section("Abacus (bank feed)") {
                Text("No transactions in last \(lookbackDays) days. Try a wider window above.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        } else {
            Section("Abacus (bank feed)") {
                HStack {
                    if loading { ProgressView() }
                    Text(loading ? "Loading…" : "Tailscale offline — pull to refresh.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var manualSection: some View {
        Section("Manual entries") {
            if revenueEntries.isEmpty {
                Text("No manual revenue logged yet.").foregroundStyle(.secondary)
            } else {
                ForEach(revenueEntries, id: \.persistentModelID) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.clientName ?? "—").font(.subheadline.weight(.semibold))
                            Text(entry.source ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(entry.amountUSD ?? 0, format: .currency(code: "USD"))
                                .fontWeight(.semibold).foregroundStyle(Brand.honeyGold)
                            Text(entry.date, style: .date).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { idx in
                    for i in idx { context.delete(revenueEntries[i]) }
                    try? context.save()
                }
            }
        }
    }

    private func loadAbacus() async {
        let settings = AbacusCredentials.loadSettings()
        abacusConnected = settings.isConfigured
        guard settings.isConfigured else { abacusSnapshot = nil; return }
        loading = true
        defer { loading = false }
        let now = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: now) ?? now
        abacusSnapshot = await AbacusService.shared.fetchWeeklySnapshot(periodStart: start, periodEnd: now)
        Log.viewModel.info("RevenueView Abacus loaded: \(self.abacusSnapshot?.revenueEntries.count ?? 0) entries (\(self.lookbackDays)d)")
    }

    private var addRevenueSheet: some View {
        NavigationStack {
            Form {
                TextField("Amount (USD)", text: $amount)
                    .keyboardType(.decimalPad)
                TextField("Client", text: $client)
                Picker("Source", selection: $source) {
                    Text("Direct").tag("direct")
                    Text("Stripe").tag("stripe")
                    Text("PayPal").tag("paypal")
                    Text("Upwork").tag("upwork")
                    Text("Kalshi").tag("kalshi")
                }
            }
            .navigationTitle("Add Revenue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let v = Double(amount), v > 0 else { return }
                        let entry = ManualEntry(
                            kind: .revenue,
                            amountUSD: v,
                            clientName: client.isEmpty ? nil : client,
                            source: source
                        )
                        context.insert(entry)
                        try? context.save()
                        amount = ""; client = ""
                        showAdd = false
                        Log.viewModel.info("Revenue logged: $\(v) from \(client)")
                    }
                }
            }
        }
    }
}
