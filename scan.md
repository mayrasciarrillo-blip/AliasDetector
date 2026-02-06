# Smart Scanner - Documentación de Lógica

## Flujo Actual

```
Home (Tab Bar)
    ↓
Tap botón cámara (centro) o "Transferir"
    ↓
ContentView se abre (fullScreenCover)
    ↓
CameraView muestra preview de cámara con escaneo continuo
    ↓
Captura automática cada ~1 segundo
    ↓
Foto se envía a analyzeImage()
    ↓
┌─────────────────────────────────────────┐
│  Clasificación Unificada (Gemini)       │
│                                         │
│  Detecta: QR / FACTURA / ALIAS          │
│  En un solo paso                        │
└─────────────────────────────────────────┘
    ↓
Si respuesta contiene "QR_DETECTADO":
    → statusMessage = "¡QR detectado!"
    → Haptic feedback
    → Abre QRPlaceholderView

Si respuesta contiene "FACTURA_SERVICIO":
    → statusMessage = "¡Factura detectada!"
    → Haptic feedback
    → Abre ServicioPlaceholderView

Si respuesta contiene alias válido:
    → aliasFound = true
    → Extrae alias con regex
    → Valida contra API local
    → Muestra ResultBottomSheet con datos

Si respuesta contiene "NO_DETECTADO":
    → Sigue escaneando
```

## Componentes

### 1. ContentView (SwiftUI) - Scanner Principal
- Vista principal del scanner unificado
- Estados: `isAnalyzing`, `aliasFound`, `aliasValidated`, `showQRLanding`, `showServicioLanding`
- Muestra `CameraView` + overlay con status pill
- Rectángulos de guía: `IdleRect`, `AnalyzingRect`, `FoundRect`

### 2. CameraView (UIViewControllerRepresentable)
- Wrapper SwiftUI para controlador de cámara
- Captura automática periódica
- Callback: `onImageCaptured`

### 3. Pantallas de resultado
- **QRPlaceholderView**: Landing "QR - próximamente"
- **ServicioPlaceholderView**: Landing "Pago de servicios - próximamente"
- **ResultBottomSheet**: Muestra datos del alias validado + botón transferir
- **TransferFlowView**: Flujo completo de transferencia

## Prompt de Gemini (Unificado)

```
System: "Sos un experto en identificar contenido en imágenes. Respondé MUY breve."

User: "Analizá la imagen.
- Si ves un código QR, respondé: QR_DETECTADO
- Si ves una factura de servicio (luz, gas, agua, teléfono, internet, expensas, cable), respondé: FACTURA_SERVICIO
- Si no es QR ni factura, buscá un alias CBU/CVU argentino (6-20 caracteres, solo letras a-z, números 0-9 y punto como separador, formato: palabra.palabra.palabra)
- Si encontrás un alias, respondé SOLO el alias
- Si no hay nada: NO_DETECTADO"
```

## Regex de Validación de Alias
```swift
let pattern = #"[a-z][a-z0-9]*(\.[a-z0-9]+)+"#
```
- Debe empezar con letra
- Puede contener letras, números y puntos
- Debe tener al menos un punto (separador)
- Longitud total: 6-20 caracteres

## Estados del Scanner

| Estado | Rectángulo | Status Pill |
|--------|------------|-------------|
| Idle | Blanco, estático | "Posicioná el alias, QR o factura en el centro" |
| Analizando | Blanco, puntos animados | "Haciendo magia ✨" |
| Encontrado | Verde, glow | "¡Verificado!" / "¡QR detectado!" / "¡Factura detectada!" |

## Archivos Involucrados

- `HomeView.swift` - Tab bar con botón de cámara
- `ContentView.swift` - Scanner unificado (QR + Factura + Alias)
- `SmartScannerView.swift` - Contiene QRPlaceholderView y ServicioPlaceholderView
- `Config.swift` - Token de Gemini y URLs
- `TransferFlowView.swift` - Flujo de transferencia post-validación
