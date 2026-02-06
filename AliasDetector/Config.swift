import Foundation

// MARK: - Configuración centralizada

struct Config {
    // Token de Gemini - expira en ~1 hora
    // Regenerar con: gcloud auth print-identity-token
    static var geminiToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImMyN2JhNDBiMDk1MjlhZDRmMTY4MjJjZTgzMTY3YzFiYzM5MTAxMjIiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIzMjU1NTk0MDU1OS5hcHBzLmdvb2dsZXVzZXJjb250ZW50LmNvbSIsImF1ZCI6IjMyNTU1OTQwNTU5LmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwic3ViIjoiMTAzNTcxODk4Njc5NDQ0MjUwNzY0IiwiaGQiOiJ1YWxhLmNvbS5hciIsImVtYWlsIjoibWF5cmEuc2NpYXJyaWxsb0B1YWxhLmNvbS5hciIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdF9oYXNoIjoiU0Z1ODdYdmZkT2FZTjJxcFNKM1M2ZyIsImlhdCI6MTc3MDM5ODMzOSwiZXhwIjoxNzcwNDAxOTM5fQ.JRJOrjH0s9a4PNw3ZZrOq7w_Gt2IHgb8SEvCYFEvEoE-3SH44fZHhVW6if_PtPUHcYFlO3Ru2dVQlku4pyTurTvGGgE0eiyUc5PkegyYJnwdKisAgGIfqyHJ3L4MkHtCFt37exgesIFic__5xotYyKXYIsv4r5Il75qLfw864LyT7yRaymavE3IE5Y5hzoNAqawHtiCYwlj-HPotiUI3XHeDDAEuxYzhX2GNbSk_T8JNBRM8tDVxdN_cUPgAN8oBKMDtGUIvyIi7dse2cEGEwZ-EKTWH-Ub-p4oAOUXtGw-482mj0ZRSYL_abhY39ZSlnWwebk3mtXHRK6xJuVy3og"

    // URL base de la API de Gemini
    static let geminiAPIUrl = "https://genai.ally.data.ua.la/data-platform/test/gemini"

    // URL base de la API local (validación de alias)
    static let localAPIUrl = "http://172.26.102.5:8000"
}
