import Foundation

// MARK: - Codable models matching the Abacus v1 integration API
// Source: J:/abacus-meatspace/INTEGRATION-REQUEST-PERFORMANCETRACKER.md
//         J:/abacus-meatspace/HANDOFF.md (v1 Integration API section)

public struct AbacusOrg: Codable, Sendable, Hashable, Identifiable {
    public let id: String         // UUID string
    public let slug: String
    public let name: String
}

public struct AbacusHealth: Codable, Sendable {
    public let status: String
    public let dbTransactionsCount: Int?
    public let lastImport: String?

    enum CodingKeys: String, CodingKey {
        case status
        case dbTransactionsCount = "db_transactions_count"
        case lastImport = "last_import"
    }
}

public struct AbacusRevenue: Codable, Sendable {
    public let orgId: String?
    public let periodStart: String
    public let periodEnd: String
    public let totalUSD: Double
    public let entries: [AbacusRevenueEntry]?

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case totalUSD = "total_usd"
        case entries
    }
}

public struct AbacusRevenueEntry: Codable, Sendable, Hashable, Identifiable {
    public let date: String
    public let amountUSD: Double
    public let clientName: String?
    public let source: String?
    public let memo: String?

    public var id: String { "\(date)-\(amountUSD)-\(clientName ?? "")-\(memo ?? "")" }

    enum CodingKeys: String, CodingKey {
        case date
        case amountUSD = "amount_usd"
        case clientName = "client_name"
        case source, memo
    }
}

public struct AbacusSpending: Codable, Sendable {
    public let orgId: String?
    public let periodStart: String
    public let periodEnd: String
    public let totalUSD: Double
    public let byCategory: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case totalUSD = "total_usd"
        case byCategory = "by_category"
    }
}

/// In-memory snapshot of Abacus data, used by the grading engine + UI.
/// Sendable struct so it crosses actor boundaries cleanly.
public struct AbacusSnapshot: Sendable, Codable {
    public let capturedAt: Date
    public let orgs: [AbacusOrg]
    public let weeklyRevenueByOrg: [String: Double]   // org id → USD
    public let weeklySpendingByOrg: [String: Double]  // org id → USD
    public let revenueEntries: [AbacusRevenueEntry]   // all orgs, this week
    public let totalRevenueWeek: Double
    public let totalSpendingWeek: Double

    public init(
        capturedAt: Date = .now,
        orgs: [AbacusOrg] = [],
        weeklyRevenueByOrg: [String: Double] = [:],
        weeklySpendingByOrg: [String: Double] = [:],
        revenueEntries: [AbacusRevenueEntry] = [],
        totalRevenueWeek: Double = 0,
        totalSpendingWeek: Double = 0
    ) {
        self.capturedAt = capturedAt
        self.orgs = orgs
        self.weeklyRevenueByOrg = weeklyRevenueByOrg
        self.weeklySpendingByOrg = weeklySpendingByOrg
        self.revenueEntries = revenueEntries
        self.totalRevenueWeek = totalRevenueWeek
        self.totalSpendingWeek = totalSpendingWeek
    }

    public var activeClientsCount: Int {
        Set(revenueEntries.compactMap(\.clientName)).count
    }
}
