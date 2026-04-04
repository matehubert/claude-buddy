import Foundation
import Security

// MARK: - Credential Manager

class CredentialManager {
    static let shared = CredentialManager()

    private let credFilePath: String
    private let keychainService = "Claude Code-credentials"
    private let refreshURL = "https://platform.claude.com/v1/oauth/token"
    private let clientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    private let scopes = "user:profile user:inference user:sessions:claude_code user:mcp_servers"
    private let refreshBufferSeconds: TimeInterval = 5 * 60

    private var cachedToken: String?
    private var cachedExpiresAt: Date?

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        credFilePath = "\(home)/.claude/.credentials.json"
    }

    struct OAuthData {
        var accessToken: String
        var refreshToken: String?
        var expiresAt: Date?
        var source: CredSource
        var fullJSON: [String: Any]
    }

    enum CredSource {
        case file
        case keychain
    }

    // MARK: - Get Valid Token

    func getAccessToken() async -> String? {
        guard let creds = readCredentials() else { return nil }

        // Check if token needs refresh
        if let expiresAt = creds.expiresAt,
           Date().addingTimeInterval(refreshBufferSeconds) > expiresAt {
            if let refreshed = await refreshToken(creds) {
                return refreshed
            }
        }

        return creds.accessToken
    }

    // MARK: - Read Credentials

    private func readCredentials() -> OAuthData? {
        // Try file first
        if let data = FileManager.default.contents(atPath: credFilePath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let oauth = json["claudeAiOauth"] as? [String: Any],
           let token = oauth["accessToken"] as? String {

            var expiresAt: Date?
            if let ts = oauth["expiresAt"] as? Double {
                expiresAt = Date(timeIntervalSince1970: ts / 1000.0)
            }

            return OAuthData(
                accessToken: token,
                refreshToken: oauth["refreshToken"] as? String,
                expiresAt: expiresAt,
                source: .file,
                fullJSON: json
            )
        }

        // Fallback: Keychain
        if let keychainData = readFromKeychain(),
           let json = try? JSONSerialization.jsonObject(with: keychainData) as? [String: Any],
           let oauth = json["claudeAiOauth"] as? [String: Any],
           let token = oauth["accessToken"] as? String {

            var expiresAt: Date?
            if let ts = oauth["expiresAt"] as? Double {
                expiresAt = Date(timeIntervalSince1970: ts / 1000.0)
            }

            return OAuthData(
                accessToken: token,
                refreshToken: oauth["refreshToken"] as? String,
                expiresAt: expiresAt,
                source: .keychain,
                fullJSON: json
            )
        }

        return nil
    }

    private func readFromKeychain() -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }

        // Data might be raw JSON or hex-encoded
        if let _ = try? JSONSerialization.jsonObject(with: data) {
            return data
        }

        // Try hex decode
        if let hexString = String(data: data, encoding: .utf8),
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
            return Data(bytes)
        }

        return nil
    }

    // MARK: - Refresh Token

    private func refreshToken(_ creds: OAuthData) async -> String? {
        guard let refreshToken = creds.refreshToken else { return nil }

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId,
            "scope": scopes
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: refreshURL) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let newToken = json["access_token"] as? String else { return nil }

            // Update stored credentials
            var updatedJSON = creds.fullJSON
            var oauth = (updatedJSON["claudeAiOauth"] as? [String: Any]) ?? [:]
            oauth["accessToken"] = newToken
            if let newRefresh = json["refresh_token"] as? String {
                oauth["refreshToken"] = newRefresh
            }
            if let expiresIn = json["expires_in"] as? Double {
                oauth["expiresAt"] = (Date().timeIntervalSince1970 + expiresIn) * 1000
            }
            updatedJSON["claudeAiOauth"] = oauth

            saveCredentials(updatedJSON, source: creds.source)
            return newToken
        } catch {
            return nil
        }
    }

    private func saveCredentials(_ json: [String: Any], source: CredSource) {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else { return }

        if source == .file {
            try? data.write(to: URL(fileURLWithPath: credFilePath))
        }
        // Keychain write omitted for safety — file source is preferred
    }

    // MARK: - Organization ID

    func getOrganizationId() -> String? {
        guard let data = FileManager.default.contents(atPath: credFilePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["organizationUuid"] as? String
    }
}
