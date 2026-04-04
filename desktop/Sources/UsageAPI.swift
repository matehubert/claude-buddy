import Foundation

// MARK: - Usage Data Models

struct UsageResponse: Codable {
    var fiveHour: UsageBucket?
    var sevenDay: UsageBucket?
    var sevenDayOpus: UsageBucket?
    var sevenDaySonnet: UsageBucket?
    var extraUsage: ExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
        case extraUsage = "extra_usage"
    }
}

struct UsageBucket: Codable {
    var utilization: Double?  // 0-100 percentage (e.g. 9.0 = 9%)
    var resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

struct ExtraUsage: Codable {
    var isEnabled: Bool?
    var monthlyLimit: Double?
    var usedCredits: Double?
    var utilization: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
}

// MARK: - Plan Info from Credentials

struct PlanInfo {
    var subscriptionType: String?  // e.g. "max_5x"
    var rateLimitTier: String?

    var displayName: String {
        switch subscriptionType {
        case "max_5x": return "Max (5x)"
        case "max_20x": return "Max (20x)"
        case "pro": return "Pro"
        case "free": return "Free"
        default: return subscriptionType ?? "Unknown"
        }
    }
}

// MARK: - Usage API Client

enum UsageResult {
    case success(UsageResponse)
    case cached(UsageResponse)
    case error(String)
}

class UsageAPI {
    static let shared = UsageAPI()

    private let usageURL = "https://api.anthropic.com/api/oauth/usage"
    private var cachedResponse: UsageResponse?
    private var cacheTime: Date?
    private var cacheTTL: TimeInterval = 300  // 5 minutes
    private var backoffUntil: Date?
    private(set) var lastError: String?

    private(set) var planInfo: PlanInfo = PlanInfo()

    private init() {
        loadPlanInfo()
    }

    private func loadPlanInfo() {
        // Read subscription info from Keychain credentials
        let keychainService = "Claude Code-credentials"
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return }

        var json: [String: Any]?
        if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = parsed
        } else if let hexString = String(data: data, encoding: .utf8),
                  hexString.allSatisfy({ $0.isHexDigit }),
                  hexString.count % 2 == 0 {
            var bytes = [UInt8]()
            var index = hexString.startIndex
            while index < hexString.endIndex {
                let nextIndex = hexString.index(index, offsetBy: 2)
                if let byte = UInt8(hexString[index..<nextIndex], radix: 16) {
                    bytes.append(byte)
                }
                index = nextIndex
            }
            json = try? JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any]
        }

        if let oauth = json?["claudeAiOauth"] as? [String: Any] {
            planInfo.subscriptionType = oauth["subscriptionType"] as? String
            planInfo.rateLimitTier = oauth["rateLimitTier"] as? String
        }
    }

    func fetchUsage() async -> UsageResponse? {
        let result = await fetchUsageWithStatus()
        switch result {
        case .success(let r): return r
        case .cached(let r): return r
        case .error: return cachedResponse
        }
    }

    func fetchUsageWithStatus() async -> UsageResult {
        // Check cache
        if let cached = cachedResponse,
           let time = cacheTime,
           Date().timeIntervalSince(time) < cacheTTL {
            lastError = nil
            return .cached(cached)
        }

        // Respect backoff
        if let until = backoffUntil, Date() < until {
            if let cached = cachedResponse {
                return .cached(cached)
            }
            return .error("Rate limited. Retry in \(Int(until.timeIntervalSinceNow))s")
        }

        guard let token = await CredentialManager.shared.getAccessToken(),
              let url = URL(string: usageURL) else {
            lastError = "No auth token"
            if let cached = cachedResponse { return .cached(cached) }
            return .error("No auth token available")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/2.1.91", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid response"
                if let cached = cachedResponse { return .cached(cached) }
                return .error("Invalid response")
            }

            if httpResponse.statusCode == 429 {
                // Rate limited — backoff using Retry-After or default 120s
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                let backoffSeconds = TimeInterval(retryAfter ?? "") ?? 120
                backoffUntil = Date().addingTimeInterval(backoffSeconds)
                cacheTTL = max(cacheTTL, backoffSeconds)
                lastError = "Rate limited (\(Int(backoffSeconds))s)"
                if let cached = cachedResponse { return .cached(cached) }
                return .error("Rate limited. Retry in \(Int(backoffSeconds))s")
            }

            guard httpResponse.statusCode == 200 else {
                lastError = "HTTP \(httpResponse.statusCode)"
                if let cached = cachedResponse { return .cached(cached) }
                return .error("HTTP \(httpResponse.statusCode)")
            }

            let usage = try JSONDecoder().decode(UsageResponse.self, from: data)
            cachedResponse = usage
            cacheTime = Date()
            lastError = nil
            backoffUntil = nil
            cacheTTL = 300
            return .success(usage)
        } catch {
            lastError = error.localizedDescription
            if let cached = cachedResponse { return .cached(cached) }
            return .error(error.localizedDescription)
        }
    }

    func invalidateCache() {
        cacheTime = nil
    }

    /// Force refresh, bypassing cache
    func forceRefresh() async -> UsageResponse? {
        cacheTime = nil
        backoffUntil = nil
        return await fetchUsage()
    }
}
