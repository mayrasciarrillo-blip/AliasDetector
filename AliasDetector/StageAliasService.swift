import Foundation

// MARK: - Stage Alias Validation Service

class StageAliasService {
    static let shared = StageAliasService()

    private let baseURL = "https://bff-transfers.api.stage.prepaid.ar.ua.la/api/v1"

    // MARK: - Models

    struct AliasInfo: Codable {
        let identifier: String?
        let name: String?
        let bank: String?
        let cuit: String?
        let accountType: String?
        let cbu: String?
        let cvu: String?

        // Computed property para obtener el nombre a mostrar
        var displayName: String {
            name ?? "Desconocido"
        }

        var displayBank: String {
            bank ?? "Entidad desconocida"
        }
    }

    enum ValidationError: Error {
        case noToken
        case networkError(Error)
        case invalidResponse
        case notFound
        case unauthorized
    }

    // MARK: - Validate Alias

    func validateAlias(_ alias: String, currency: String = "ars") async -> Result<AliasInfo, ValidationError> {
        // Asegurar token válido
        guard await StageAuthService.shared.ensureValidToken(),
              let token = StageAuthService.shared.cognitoToken else {
            print("❌ No valid stage token")
            return .failure(.noToken)
        }

        let encodedAlias = alias.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? alias
        guard let url = URL(string: "\(baseURL)/identifiers/info?identifier=\(encodedAlias)&currency=\(currency)") else {
            return .failure(.invalidResponse)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            switch http.statusCode {
            case 200:
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let aliasInfo = try decoder.decode(AliasInfo.self, from: data)
                print("✅ Alias validado en Stage: \(alias)")
                return .success(aliasInfo)

            case 401, 403:
                // Token expirado, refrescar e intentar de nuevo (una vez)
                print("🔄 Token expirado, refrescando...")
                StageAuthService.shared.clearToken()
                if await StageAuthService.shared.authenticate() {
                    // Reintentar una vez
                    return await validateAliasWithoutRetry(alias, currency: currency)
                }
                return .failure(.unauthorized)

            case 404:
                print("❌ Alias no encontrado: \(alias)")
                return .failure(.notFound)

            default:
                print("❌ Stage API error: \(http.statusCode)")
                if let body = String(data: data, encoding: .utf8) {
                    print("Response: \(body)")
                }
                return .failure(.invalidResponse)
            }

        } catch {
            print("❌ Stage validation error: \(error)")
            return .failure(.networkError(error))
        }
    }

    // Validación sin retry (para evitar loops infinitos)
    private func validateAliasWithoutRetry(_ alias: String, currency: String) async -> Result<AliasInfo, ValidationError> {
        guard let token = StageAuthService.shared.cognitoToken else {
            return .failure(.noToken)
        }

        let encodedAlias = alias.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? alias
        guard let url = URL(string: "\(baseURL)/identifiers/info?identifier=\(encodedAlias)&currency=\(currency)") else {
            return .failure(.invalidResponse)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .failure(.invalidResponse)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let aliasInfo = try decoder.decode(AliasInfo.self, from: data)
            return .success(aliasInfo)

        } catch {
            return .failure(.networkError(error))
        }
    }

    // MARK: - Convenience method (returns optional)

    func validateAliasSimple(_ alias: String) async -> AliasInfo? {
        let result = await validateAlias(alias)
        switch result {
        case .success(let info):
            return info
        case .failure:
            return nil
        }
    }
}
