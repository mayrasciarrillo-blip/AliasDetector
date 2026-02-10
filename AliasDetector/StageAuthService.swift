import Foundation

// MARK: - Stage Authentication Service

class StageAuthService {
    static let shared = StageAuthService()

    private let auth0URL = "https://uala-arg-app-stage.us.auth0.com/oauth/token"
    private let clientId = "DMJf1oKKYwgb66G7Pfb1WSfzBv48Va6j"
    private let audience = "https://uala-arg-app-stage"

    // Credenciales de test (en producción vendrían del login)
    private let testUsername = "success+708694207@simulator.amazonses.com"
    private let testPassword = "Passw0rd!"

    // Token almacenado
    private(set) var cognitoToken: String? {
        get { UserDefaults.standard.string(forKey: "stageCognitoToken") }
        set { UserDefaults.standard.set(newValue, forKey: "stageCognitoToken") }
    }

    private(set) var tokenExpiration: Date? {
        get { UserDefaults.standard.object(forKey: "stageTokenExpiration") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "stageTokenExpiration") }
    }

    var isTokenValid: Bool {
        guard let token = cognitoToken, let expiration = tokenExpiration else { return false }
        return !token.isEmpty && Date() < expiration
    }

    // MARK: - Auth0 Login

    func authenticate() async -> Bool {
        guard let url = URL(string: auth0URL) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "grant_type": "password",
            "username": testUsername,
            "password": testPassword,
            "client_id": clientId,
            "audience": audience,
            "scope": "openid profile email offline_access",
            "connection": "Uala-Database",
            "device": "00000"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("❌ Auth0 error: status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return false
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                print("❌ No access_token in response")
                return false
            }

            // Extraer Cognito token del JWT
            if let cognitoToken = extractCognitoToken(from: accessToken) {
                self.cognitoToken = cognitoToken
                self.tokenExpiration = Date().addingTimeInterval(25 * 60) // 25 min (conservador)
                print("✅ Stage token obtenido")
                return true
            }

            return false
        } catch {
            print("❌ Auth error: \(error)")
            return false
        }
    }

    // MARK: - Extract Cognito Token from JWT

    private func extractCognitoToken(from jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }

        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Padding
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cognitoToken = json["http://cognito-proxy.ua.la/cognito_access_token"] as? String else {
            return nil
        }

        return cognitoToken
    }

    // MARK: - Refresh if needed

    func ensureValidToken() async -> Bool {
        if isTokenValid {
            return true
        }
        return await authenticate()
    }

    func clearToken() {
        cognitoToken = nil
        tokenExpiration = nil
    }
}
