import Foundation
import UIKit

// MARK: - Stage Transfer Service

class StageTransferService {
    static let shared = StageTransferService()

    private let endpoint = "https://services.uala.com.ar/stage/bancar/api/3/transactional/transfer/cashout"

    // MARK: - Models

    struct TransferResponse: Codable {
        let authorizationId: String?
        let transactionId: String?

        enum CodingKeys: String, CodingKey {
            case authorizationId = "authorization_id"
            case transactionId = "transaction_id"
        }
    }

    enum TransferError: Error, LocalizedError {
        case noToken
        case networkError(Error)
        case invalidResponse
        case serverError(Int, String)
        case unauthorized

        var errorDescription: String? {
            switch self {
            case .noToken:
                return "No se pudo autenticar. Intentá de nuevo."
            case .networkError:
                return "Error de conexión. Verificá tu internet."
            case .invalidResponse:
                return "Respuesta inesperada del servidor."
            case .serverError(let code, let message):
                return "Error del servidor (\(code)): \(message)"
            case .unauthorized:
                return "Sesión expirada. Intentá de nuevo."
            }
        }
    }

    // MARK: - Execute Transfer

    func executeTransfer(
        amount: Double,
        aliasData: AliasData,
        category: String
    ) async -> Result<TransferResponse, TransferError> {
        // Asegurar token válido
        guard await StageAuthService.shared.ensureValidToken(),
              let token = StageAuthService.shared.cognitoToken else {
            print("❌ No valid stage token for transfer")
            return .failure(.noToken)
        }

        guard let url = URL(string: endpoint) else {
            return .failure(.invalidResponse)
        }

        let deviceId = await MainActor.run {
            UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        }

        let body: [String: Any] = [
            "amount": amount,
            "bankId": aliasData.bankId,
            "beneficiary": aliasData.nombreCompleto,
            "category": category,
            "comment": "",
            "concept": "VAR",
            "destination": aliasData.cvu,
            "destinationName": aliasData.nombreCompleto,
            "destinationTaxDocument": aliasData.cuitCuil,
            "DeviceId": deviceId,
            "financialEntity": aliasData.entidad,
            "isTrinity": false,
            "pin": "135790"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let bodyJson = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
            print("📤 Transfer REQUEST body: \(bodyJson)")

            let (data, response) = try await URLSession.shared.data(for: request)

            let responseBody = String(data: data, encoding: .utf8) ?? "sin body"
            guard let http = response as? HTTPURLResponse else {
                print("❌ Transfer: no HTTP response")
                return .failure(.invalidResponse)
            }

            print("📥 Transfer RESPONSE [\(http.statusCode)]: \(responseBody)")

            switch http.statusCode {
            case 200, 201, 202:
                let decoder = JSONDecoder()
                if let transferResponse = try? decoder.decode(TransferResponse.self, from: data) {
                    print("✅ Transferencia exitosa")
                    return .success(transferResponse)
                }
                print("✅ Transferencia exitosa (sin body decodificable)")
                return .success(TransferResponse(authorizationId: nil, transactionId: nil))

            case 401, 403:
                print("🔄 Token expirado en transfer, refrescando...")
                StageAuthService.shared.clearToken()
                if await StageAuthService.shared.authenticate() {
                    return await executeTransferWithoutRetry(amount: amount, aliasData: aliasData, category: category)
                }
                return .failure(.unauthorized)

            default:
                print("❌ Transfer API error: \(http.statusCode) - \(responseBody)")
                return .failure(.serverError(http.statusCode, responseBody))
            }

        } catch {
            print("❌ Transfer network error: \(error)")
            return .failure(.networkError(error))
        }
    }

    // Retry sin loop infinito
    private func executeTransferWithoutRetry(
        amount: Double,
        aliasData: AliasData,
        category: String
    ) async -> Result<TransferResponse, TransferError> {
        guard let token = StageAuthService.shared.cognitoToken else {
            return .failure(.noToken)
        }

        guard let url = URL(string: endpoint) else {
            return .failure(.invalidResponse)
        }

        let deviceId = await MainActor.run {
            UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        }

        let body: [String: Any] = [
            "amount": amount,
            "bankId": aliasData.bankId,
            "beneficiary": aliasData.nombreCompleto,
            "category": category,
            "comment": "",
            "concept": "VAR",
            "destination": aliasData.cvu,
            "destinationName": aliasData.nombreCompleto,
            "destinationTaxDocument": aliasData.cuitCuil,
            "DeviceId": deviceId,
            "financialEntity": aliasData.entidad,
            "isTrinity": false,
            "pin": "135790"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return .failure(.invalidResponse)
            }

            if let transferResponse = try? JSONDecoder().decode(TransferResponse.self, from: data) {
                return .success(transferResponse)
            }
            return .success(TransferResponse(authorizationId: nil, transactionId: nil))

        } catch {
            return .failure(.networkError(error))
        }
    }
}
