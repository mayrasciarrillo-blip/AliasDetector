import Foundation

// MARK: - Configuración centralizada

struct Config {
    // Token de Gemini - se obtiene del servidor automáticamente
    static var geminiToken: String {
        get { UserDefaults.standard.string(forKey: "geminiToken") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "geminiToken") }
    }

    // URL base de la API de Gemini
    static let geminiAPIUrl = "https://genai.ally.data.ua.la/data-platform/test/gemini"

    // URL base de la API local (validación de alias y token)
    static let localAPIUrl = "http://192.168.1.133:8000"

    // Obtener token fresco del servidor
    static func refreshToken() async -> Bool {
        guard let url = URL(string: "\(localAPIUrl)/token") else { return false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["token"] as? String {
                geminiToken = token
                print("Token actualizado correctamente")
                return true
            }
        } catch {
            print("Error obteniendo token: \(error)")
        }
        return false
    }

    // MARK: - Stage Configuration

    /// Toggle para usar API de Stage en lugar de mock local
    /// Cambiar a `true` cuando se tengan permisos en Stage
    static let useStageAPI = false

    /// URL base de la API de transfers en Stage
    static let stageTransfersURL = "https://bff-transfers.api.stage.prepaid.ar.ua.la/api/v1"
}
