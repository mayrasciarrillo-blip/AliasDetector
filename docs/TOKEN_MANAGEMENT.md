# Gestión de Token - AliasDetector

## Resumen

La app utiliza un token de Google Cloud Identity para autenticarse contra la API de Gemini. Este token expira aproximadamente cada hora y necesita ser renovado.

---

## Arquitectura

```
┌─────────────┐     GET /token      ┌─────────────┐     gcloud auth      ┌─────────────┐
│   iPhone    │ ──────────────────► │  API Local  │ ──────────────────► │   Google    │
│   (App)     │ ◄────────────────── │  (Python)   │ ◄────────────────── │   Cloud     │
└─────────────┘    { token: "..." } └─────────────┘   identity-token     └─────────────┘
       │
       │ Authorization: Bearer <token>
       ▼
┌─────────────┐
│  Gemini API │
└─────────────┘
```

---

## Componentes

### 1. API Local (Python - `mock_db/api.py`)

Endpoint `/token` que obtiene un token fresco de Google Cloud:

```python
@app.get("/token")
def get_token():
    token = subprocess.check_output(
        ["gcloud", "auth", "print-identity-token"],
        text=True
    ).strip()
    return {"token": token}
```

**Ubicación:** `http://<IP_LOCAL>:8000/token`

### 2. Config.swift (iOS)

Almacena el token en `UserDefaults` y provee método para refrescarlo:

```swift
struct Config {
    // Token persistido en UserDefaults
    static var geminiToken: String {
        get { UserDefaults.standard.string(forKey: "geminiToken") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "geminiToken") }
    }

    static let localAPIUrl = "http://192.168.1.133:8000"

    // Obtener token fresco del servidor
    static func refreshToken() async -> Bool {
        guard let url = URL(string: "\(localAPIUrl)/token") else { return false }

        let (data, _) = try await URLSession.shared.data(from: url)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["token"] as? String {
            geminiToken = token  // Guarda en UserDefaults
            return true
        }
        return false
    }
}
```

### 3. AliasDetectorApp.swift

Refresca el token cada vez que la app vuelve a primer plano (incluyendo cold start y vuelta de background):

```swift
@main
struct AliasDetectorApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    let success = await Config.refreshToken()
                    if success {
                        print("✅ Token actualizado (app activa)")
                    }
                }
            }
        }
    }
}
```

### 4. ContentView.swift - Retry Logic

Si una llamada a Gemini falla con 401/403, refresca el token y reintenta:

```swift
URLSession.shared.dataTask(with: request) { data, response, error in
    // Si el token expiró (401/403), refrescar y reintentar
    if let http = response as? HTTPURLResponse,
       (http.statusCode == 401 || http.statusCode == 403) {
        Task {
            let refreshed = await Config.refreshToken()
            if refreshed {
                self.analyzeImageForAlias(image)  // Reintentar
            }
        }
        return
    }
    // ... procesar respuesta normal
}
```

---

## Flujo de Ejecución

### Caso 1: App se inicia (Cold Start)
```
1. init() de AliasDetectorApp se ejecuta
2. Task async llama a Config.refreshToken()
3. refreshToken() hace GET a /token
4. API local ejecuta `gcloud auth print-identity-token`
5. Token se guarda en UserDefaults
6. App lista para usar Gemini
```

### Caso 2: Token expira durante uso
```
1. Usuario escanea imagen
2. App llama a Gemini API con token expirado
3. Gemini responde 401/403
4. ContentView detecta el error
5. Llama a Config.refreshToken()
6. Obtiene token nuevo
7. Reintenta la llamada a Gemini
```

### Caso 3: App vuelve de background (PROBLEMA ACTUAL)
```
1. App estaba en background
2. Usuario la abre de nuevo
3. init() NO se ejecuta (no es cold start)
4. Token podría estar expirado
5. Depende del retry logic (caso 2)
```

---

## Problemas Identificados

### 1. Refresh solo en Cold Start
El `init()` de SwiftUI App solo se ejecuta cuando la app inicia desde cero, no cuando vuelve de background.

**Solución propuesta:** Agregar refresh en `onAppear` o usar `scenePhase` para detectar cuando la app vuelve a primer plano.

### 2. Race Condition en Startup
El `Task {}` en `init()` es asíncrono. La app puede intentar usar Gemini antes de que el token esté listo.

**Solución propuesta:** Mostrar loading state hasta que el token esté disponible, o hacer el refresh síncrono.

### 3. Sin límite de reintentos
Si el retry falla repetidamente, podría causar un loop infinito.

**Solución propuesta:** Agregar contador de reintentos máximos.

---

## Configuración Requerida

1. **API Local corriendo:**
   ```bash
   cd mock_db && python3 api.py
   ```

2. **gcloud autenticado:**
   ```bash
   gcloud auth login
   ```

3. **IP correcta en Config.swift:**
   ```swift
   static let localAPIUrl = "http://<TU_IP>:8000"
   ```

4. **iPhone en la misma red WiFi que la Mac**

---

## Verificación

### Probar endpoint de token:
```bash
curl http://192.168.1.133:8000/token
```

### Ver logs de la API:
Los requests del iPhone aparecerán en la consola donde corre `python3 api.py`

### Verificar en Xcode Console:
Buscar mensajes:
- `✅ Token actualizado al iniciar la app`
- `🔄 Token refrescado, reintentando...`
- `⚠️ No se pudo actualizar el token al iniciar`
