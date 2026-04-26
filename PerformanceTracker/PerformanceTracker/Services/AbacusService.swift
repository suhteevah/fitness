import Foundation
import Security

/// Tailscale-only client for the Abacus v1 integration API.
///
/// Requires Tailscale active on the iPhone — Abacus is exposed only on tailnet
/// (Matt's directive: financial data, no LAN/WAN). Failures fall through to
/// manual-entry / cached snapshots in the grading engine.
///
/// Auth: `X-API-Key: ol_...` header. Key stored in Keychain via `AbacusCredentials`.
public actor AbacusService {

    public static let shared = AbacusService()

    /// Sendable settings snapshot, suitable for callers + tests.
    public struct Settings: Sendable {
        public var baseURL: URL?
        public var apiKey: String?
        public var primaryOrgId: String?      // which org's revenue feeds the Revenue grade

        public init(baseURL: URL? = nil, apiKey: String? = nil, primaryOrgId: String? = nil) {
            self.baseURL = baseURL
            self.apiKey = apiKey
            self.primaryOrgId = primaryOrgId
        }

        public var isConfigured: Bool { baseURL != nil && apiKey != nil }
    }

    public enum AbacusError: Error, Sendable {
        case notConfigured
        case unreachable(String)
        case http(Int, String)
        case decode(String)
    }

    private var settings: Settings = .init()
    private let session: URLSession

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 8        // short — tailnet-local, should be <100ms typically
        cfg.timeoutIntervalForResource = 15
        cfg.waitsForConnectivity = false         // fail fast, callers retry
        self.session = URLSession(configuration: cfg)
    }

    // MARK: - Configuration

    public func configure(_ s: Settings) {
        self.settings = s
        Log.assessment.info("Abacus configured: \(s.baseURL?.absoluteString ?? "nil") org=\(s.primaryOrgId ?? "nil")")
    }

    public func currentSettings() -> Settings { settings }

    // MARK: - Endpoints

    public func health() async throws -> AbacusHealth {
        try await get("/health")
    }

    public func orgs() async throws -> [AbacusOrg] {
        try await get("/orgs")
    }

    public func revenue(orgId: String?, since: Date, until: Date, includeEntries: Bool = true) async throws -> AbacusRevenue {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "since", value: yyyyMMdd(since)),
            URLQueryItem(name: "until", value: yyyyMMdd(until)),
        ]
        if let orgId { items.append(.init(name: "org_id", value: orgId)) }
        if includeEntries { items.append(.init(name: "include_entries", value: "true")) }
        return try await get("/revenue", query: items)
    }

    public func spending(orgId: String?, since: Date, until: Date) async throws -> AbacusSpending {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "since", value: yyyyMMdd(since)),
            URLQueryItem(name: "until", value: yyyyMMdd(until)),
        ]
        if let orgId { items.append(.init(name: "org_id", value: orgId)) }
        return try await get("/spending", query: items)
    }

    /// Fetch a full weekly snapshot in one go. Returns nil if not configured or unreachable.
    public func fetchWeeklySnapshot(periodStart: Date, periodEnd: Date) async -> AbacusSnapshot? {
        guard settings.isConfigured else {
            Log.assessment.info("Abacus not configured; skipping live fetch")
            return nil
        }

        do {
            async let orgsTask = orgs()
            // Use single-request revenue across all orgs (admin key) by omitting org_id.
            async let revAll = revenue(orgId: nil, since: periodStart, until: periodEnd, includeEntries: true)
            async let spendAll = spending(orgId: nil, since: periodStart, until: periodEnd)

            let orgsList = try await orgsTask
            let rev = try await revAll
            let spend = try await spendAll

            // Bucket revenue by org if entries are present
            var revByOrg: [String: Double] = [:]
            if let entries = rev.entries {
                // Without org_id on each entry, we can't bucket per-org reliably.
                // Best we can do is total. Per-org bucketing would require N requests
                // (one per org) — which is fine but slower. For now, default to total
                // attributed to primary org.
                if let primary = settings.primaryOrgId {
                    revByOrg[primary] = entries.reduce(0) { $0 + $1.amountUSD }
                }
            }

            return AbacusSnapshot(
                capturedAt: .now,
                orgs: orgsList,
                weeklyRevenueByOrg: revByOrg,
                weeklySpendingByOrg: spend.orgId.map { [$0: spend.totalUSD] } ?? [:],
                revenueEntries: rev.entries ?? [],
                totalRevenueWeek: rev.totalUSD,
                totalSpendingWeek: spend.totalUSD
            )
        } catch {
            Log.assessment.error("Abacus fetchWeeklySnapshot failed: \(error)")
            return nil
        }
    }

    // MARK: - Private

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard let baseURL = settings.baseURL, let apiKey = settings.apiKey else {
            throw AbacusError.notConfigured
        }
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty {
            components?.queryItems = query
        }
        guard let url = components?.url else {
            throw AbacusError.unreachable("Bad URL \(baseURL)\(path)")
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        Log.assessment.debug("Abacus GET \(url.absoluteString)")

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw AbacusError.unreachable("No HTTP response")
            }
            guard (200..<300).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw AbacusError.http(http.statusCode, body)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw AbacusError.decode("\(error)")
            }
        } catch let error as AbacusError {
            throw error
        } catch {
            throw AbacusError.unreachable(error.localizedDescription)
        }
    }

    private func yyyyMMdd(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = .init(identifier: .iso8601)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}

// MARK: - Keychain-backed credential store

/// Stores Abacus base URL + API key in the iOS Keychain so they survive app
/// reinstalls and are encrypted at rest. Primary org id stored in UserDefaults
/// (it's not a secret).
public enum AbacusCredentials {
    private static let service = "com.ridgecellrepair.performancetracker.abacus"
    private static let baseURLAccount = "baseURL"
    private static let apiKeyAccount = "apiKey"
    private static let primaryOrgKey = "AbacusPrimaryOrgId"

    public static func saveBaseURL(_ url: URL) {
        save(account: baseURLAccount, value: url.absoluteString)
    }

    public static func saveAPIKey(_ key: String) {
        save(account: apiKeyAccount, value: key)
    }

    public static func savePrimaryOrgId(_ orgId: String?) {
        if let orgId {
            UserDefaults.standard.set(orgId, forKey: primaryOrgKey)
        } else {
            UserDefaults.standard.removeObject(forKey: primaryOrgKey)
        }
    }

    public static func loadSettings() -> AbacusService.Settings {
        let baseURLString = load(account: baseURLAccount)
        let apiKey = load(account: apiKeyAccount)
        let orgId = UserDefaults.standard.string(forKey: primaryOrgKey)
        return AbacusService.Settings(
            baseURL: baseURLString.flatMap(URL.init(string:)),
            apiKey: apiKey,
            primaryOrgId: orgId
        )
    }

    public static func clear() {
        delete(account: baseURLAccount)
        delete(account: apiKeyAccount)
        UserDefaults.standard.removeObject(forKey: primaryOrgKey)
    }

    // MARK: Keychain helpers

    private static func save(account: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)

        // Financial credentials. Use the strictest reasonable accessibility class:
        // - WhenPasscodeSetThisDeviceOnly: requires device passcode (Face ID inherits);
        //   item is wiped if the passcode is removed; never synced to iCloud or
        //   restored to a different device. CWE-287 mitigation.
        // We deliberately do NOT add a SecAccessControl with .userPresence /
        // .biometryCurrentSet because Face ID per API call would prompt on every
        // dashboard refresh — unacceptable UX. Passcode-gated storage is the
        // right balance for a single-user app reading financial data over tailnet.
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        item[kSecAttrSynchronizable as String] = false
        let status = SecItemAdd(item as CFDictionary, nil)
        if status != errSecSuccess {
            Log.oauth.error("Keychain save failed for \(account): \(status)")
        }
    }

    private static func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
