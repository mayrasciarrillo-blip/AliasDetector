# Smart Scanner - Documentación Técnica

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    ContentView (Scanner)                     │
├─────────────────────────────────────────────────────────────┤
│  CameraView                                                  │
│  ├── AVCaptureSession (preview)                             │
│  ├── Vision Framework (QR/Barcode detection) ──► Instantáneo│
│  └── CoreMotion (estabilidad) ──► Gemini (alias OCR)        │
└─────────────────────────────────────────────────────────────┘
```

## Flujo de Detección

```
[Camera Preview activo]
    │
    ├── Vision Framework (cada frame)
    │   ├── VNDetectBarcodesRequest
    │   │   ├── QR detectado → acumular código
    │   │   └── Barcode detectado → acumular código
    │   │
    │   └── Después de 0.5s de acumulación:
    │       ├── Solo QR → delay 1s → PaymentView (.qr)
    │       ├── Solo Barcode → delay 1s → PaymentView (.barcode)
    │       └── Ambos → CodeSelectionMenu
    │
    └── CoreMotion (cada 0.1s)
        └── Si dispositivo estable (delta < 0.4):
            └── Capturar imagen → Gemini API
                └── Si alias encontrado → validar → TransferFlow
```

## Detección con Vision Framework

### Configuración
```swift
let request = VNDetectBarcodesRequest { request, error in
    guard let results = request.results as? [VNBarcodeObservation] else { return }

    for barcode in results {
        if barcode.symbology == .qr {
            // QR detectado
        } else {
            // Barcode detectado (EAN, Code128, etc.)
        }
    }
}
request.symbologies = [.qr, .ean13, .ean8, .code128, .code39, .upce]
```

### Tipos de Código Soportados
| Tipo | Symbology | Uso |
|------|-----------|-----|
| QR | `.qr` | Pagos QR |
| EAN-13 | `.ean13` | Productos, facturas |
| EAN-8 | `.ean8` | Productos pequeños |
| Code 128 | `.code128` | Logística, facturas |
| Code 39 | `.code39` | Industrial |
| UPC-E | `.upce` | Productos USA |

## Detección de Estabilidad (CoreMotion)

### Configuración
```swift
private let stabilityThreshold: Double = 0.4
private var lastAcceleration: (x: Double, y: Double, z: Double)?

motionManager.accelerometerUpdateInterval = 0.1
motionManager.startAccelerometerUpdates(to: .main) { data, _ in
    if let last = self.lastAcceleration {
        let deltaX = abs(data.acceleration.x - last.x)
        let deltaY = abs(data.acceleration.y - last.y)
        let deltaZ = abs(data.acceleration.z - last.z)
        let movement = deltaX + deltaY + deltaZ
        self.isDeviceStable = movement < self.stabilityThreshold
    }
    self.lastAcceleration = (data.acceleration.x, data.acceleration.y, data.acceleration.z)
}
```

### Por qué Delta y no Absoluto
- El acelerómetro siempre mide gravedad (~1g en Z)
- Medir valores absolutos no detecta movimiento real
- El delta entre frames detecta cambios = movimiento del usuario

## Acumulación de Códigos Múltiples

### Lógica
```swift
private var accumulatedCodes: [String: DetectedCode] = [:]
private var accumulationStartTime: Date?
private let accumulationWindow: TimeInterval = 0.5

func processDetectedCode(_ code: DetectedCode) {
    if accumulationStartTime == nil {
        accumulationStartTime = Date()
    }

    accumulatedCodes[code.payload] = code

    // Después de 0.5s, procesar todos los códigos acumulados
    if Date().timeIntervalSince(accumulationStartTime!) >= accumulationWindow {
        let codes = Array(accumulatedCodes.values)

        if codes.count == 1 {
            // Un solo código → procesar directo
            processCode(codes[0])
        } else {
            // Múltiples códigos → mostrar menú
            showCodeSelectionMenu(codes)
        }

        resetAccumulation()
    }
}
```

## Detección de Alias (Gemini AI)

### Prompt
```
System: "Sos un OCR. Respondé breve."

User: "Buscá un alias CBU/CVU en la imagen (formato palabra.palabra,
6-20 caracteres, solo letras/números/puntos). Si lo encontrás,
respondé SOLO el alias. Si no hay alias, respondé NO_ALIAS."
```

### Regex de Validación
```swift
let pattern = #"[a-z][a-z0-9]*(\.[a-z0-9]+)+"#
// Ejemplos válidos: belen.suarez, juan.perez.mp, mi.alias.123
```

### Retry en Token Expirado
```swift
if http.statusCode == 401 || http.statusCode == 403 {
    if retryCount < maxRetries {
        Task {
            let refreshed = await Config.refreshToken()
            if refreshed {
                self.analyzeImageForAlias(image, retryCount: retryCount + 1)
            }
        }
    }
}
```

## Menú de Selección de Código

### CodeSelectionMenu
```swift
struct CodeSelectionMenu: View {
    let codes: [DetectedCode]
    let onSelect: (DetectedCode) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack {
            Text("¿Qué querés pagar?")

            ForEach(codes) { code in
                Button(action: { onSelect(code) }) {
                    HStack {
                        Image(systemName: code.type == .qr ? "qrcode" : "barcode")
                        Text(code.type == .qr ? "Pagar con QR" : "Pagar con Código de Barras")
                    }
                }
            }

            Button("Cancelar") { onCancel() }
        }
    }
}
```

## PaymentView (Abstracta)

### PaymentType
```swift
enum PaymentType {
    case qr
    case barcode

    var title: String {
        switch self {
        case .qr: return "Pagar QR"
        case .barcode: return "Pagar Servicio"
        }
    }
}
```

### Datos Mock por Tipo
| Tipo | Destinatario | Monto |
|------|--------------|-------|
| QR | Crujen Milanesas | $11.000 |
| Barcode | Edenor | $155.000 |

## Estados del Scanner

| Estado | Indicador Visual | Descripción |
|--------|------------------|-------------|
| Idle | Status pill | "Posicioná el alias, QR o código de barras" |
| Analizando | Spinner | "Procesando la imagen" |
| QR/Barcode | Haptic + delay | Espera 1s antes de navegar |
| Alias encontrado | Validando | "Validando alias" |
| Multi-código | Menú | Selección de qué pagar |

## Archivos Involucrados

| Archivo | Responsabilidad |
|---------|-----------------|
| `ContentView.swift` | Scanner principal, lógica de detección |
| `CameraView.swift` | AVFoundation, Vision, CoreMotion |
| `PaymentView.swift` | Vista de pago (QR/Barcode) |
| `TransferFlow.swift` | Flujo de transferencia (alias) |
| `HomeView.swift` | Tab bar, navegación |
| `Config.swift` | Token, URLs, refresh |
| `AliasDetectorApp.swift` | Entry point, scenePhase |

## Gestión de Token

Ver documentación completa en `docs/TOKEN_MANAGEMENT.md`

### Resumen
1. Refresh automático cuando app vuelve a foreground
2. Retry automático en 401/403 (máximo 1 vez)
3. Token almacenado en UserDefaults
4. Endpoint `/token` en API local
