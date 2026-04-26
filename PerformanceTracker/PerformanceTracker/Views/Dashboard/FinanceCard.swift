import SwiftUI

/// Compact finance summary on the Dashboard. Driven by AbacusService snapshot.
public struct FinanceCard: View {
    public let snapshot: AbacusSnapshot?
    public let isConnected: Bool
    public let lookbackDays: Int
    public let onLookbackChange: ((Int) -> Void)?

    public init(snapshot: AbacusSnapshot?, isConnected: Bool, lookbackDays: Int = 30, onLookbackChange: ((Int) -> Void)? = nil) {
        self.snapshot = snapshot
        self.isConnected = isConnected
        self.lookbackDays = lookbackDays
        self.onLookbackChange = onLookbackChange
    }

    @State private var showLog = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "dollarsign.circle.fill").foregroundStyle(Brand.honeyGold)
                Text("Finance").font(.subheadline.weight(.semibold))
                Spacer()
                if !isConnected {
                    Text("Not connected").font(.caption2).foregroundStyle(.secondary)
                } else if snapshot == nil {
                    Text("Tailscale offline").font(.caption2).foregroundStyle(.secondary)
                } else {
                    Text("Tailnet · live").font(.caption2).foregroundStyle(Brand.seaGlassTeal)
                }
            }
            if let s = snapshot {
                HStack(alignment: .firstTextBaseline) {
                    Text(s.totalRevenueWeek, format: .currency(code: "USD"))
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Brand.honeyGold)
                    Text("last \(lookbackDays) days").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if onLookbackChange != nil {
                        Menu {
                            ForEach([7, 30, 90, 365], id: \.self) { d in
                                Button {
                                    onLookbackChange?(d)
                                } label: {
                                    HStack {
                                        Text("\(d) days")
                                        if d == lookbackDays { Image(systemName: "checkmark") }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "calendar.badge.clock").font(.caption)
                                .foregroundStyle(Brand.softIris)
                        }
                    }
                }
                if s.totalSpendingWeek > 0 {
                    HStack {
                        Text("Spending").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(s.totalSpendingWeek, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                    }
                }
                HStack {
                    Text("Active clients").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(s.activeClientsCount)").font(.caption.weight(.semibold))
                }
                if !s.revenueEntries.isEmpty {
                    Button {
                        showLog = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet.rectangle")
                            Text("View transactions (\(s.revenueEntries.count))")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.softIris)
                    }
                    .padding(.top, 2)
                } else {
                    Text("No revenue entries in last \(lookbackDays) days. Try a wider window via the calendar icon.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if !isConnected {
                Text("Connect via Settings → Abacus")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Reconnect to Tailscale to refresh (pull down).")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .sheet(isPresented: $showLog) {
            if let s = snapshot {
                RevenueLogView(entries: s.revenueEntries, total: s.totalRevenueWeek)
            }
        }
    }
}

private struct RevenueLogView: View {
    let entries: [AbacusRevenueEntry]
    let total: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(total, format: .currency(code: "USD"))
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Brand.honeyGold)
                    }
                }
                Section("Transactions") {
                    ForEach(entries.sorted(by: { $0.date > $1.date })) { e in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(e.clientName ?? e.source ?? "—")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(e.amountUSD, format: .currency(code: "USD"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.honeyGold)
                            }
                            HStack {
                                Text(e.date).font(.caption).foregroundStyle(.secondary)
                                if let memo = e.memo, !memo.isEmpty {
                                    Text("·").font(.caption).foregroundStyle(.secondary)
                                    Text(memo).font(.caption).foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Revenue Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
