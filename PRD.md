# AliasDetector - Product Requirements Document

## Descripción General
App iOS nativa para realizar transferencias bancarias mediante alias CBU/CVU, con scanner inteligente que detecta automáticamente alias, códigos QR y códigos de barras usando Vision Framework y Gemini AI.

## Funcionalidades Principales

### 1. Smart Scanner (Detección Inteligente)
El scanner unificado detecta automáticamente tres tipos de contenido:

#### 1.1 Detección de Código QR (Vision Framework)
- Detección instantánea usando `VNDetectBarcodesRequest`
- Delay de 1 segundo antes de mostrar pantalla de pago
- Flujo: "Pagar QR" con datos mock (Crujen Milanesas, $11.000)

#### 1.2 Detección de Código de Barras (Vision Framework)
- Detección instantánea de múltiples formatos (EAN, Code128, etc.)
- Delay de 1 segundo antes de mostrar pantalla de pago
- Flujo: "Pagar Servicio" con datos mock (Edenor, $155.000)

#### 1.3 Detección de Alias CBU/CVU (Gemini AI)
- OCR usando Gemini 2.5 Flash
- Detección solo cuando el dispositivo está estable (CoreMotion)
- Formato: `palabra.palabra` (6-20 caracteres)
- Validación contra API local

#### 1.4 Detección Múltiple
- Cuando se detectan QR y código de barras simultáneamente
- Ventana de acumulación de 0.5 segundos
- Menú inferior para seleccionar qué pagar:
  - "Pagar con QR"
  - "Pagar con Código de Barras"

### 2. Validación de Alias
- Validación contra API local (FastAPI)
- Muestra datos del destinatario:
  - Nombre completo
  - Banco/Entidad
  - Tipo de cuenta (CBU/CVU)
  - CUIT/CUIL

### 3. Flujo de Pago (PaymentView)

#### 3.1 Pantalla de Monto
- Display de monto con formato argentino
- Montos rápidos predefinidos: $100, $5.000, $10.000
- Teclado numérico para ingreso manual
- Indicador de dinero disponible

#### 3.2 Confirmación
- Datos del destinatario/servicio
- Monto a pagar
- Botón de confirmación

#### 3.3 Pantalla de Éxito (SuccessView)
- Animación de celebración (confetti, emojis)
- Haptic feedback
- Resumen de la transferencia
- Botón "Genial" que vuelve a Home

### 4. Home y Navegación

#### 4.1 Tab Bar (Liquid Glass Style)
- Diseño compacto con efecto glass
- Fondo semi-transparente blanquecino
- Iconos grises uniformes
- Tabs: Inicio, Tarjeta, [Scanner], Actividad, Menú

#### 4.2 Acciones Rápidas
- Transferir (abre scanner)
- Recargar celular
- Pagar servicios
- Ver CBU

## Especificaciones Técnicas

### Stack
- SwiftUI (iOS 17+)
- AVFoundation (cámara)
- Vision Framework (QR/Barcode detection)
- CoreMotion (estabilidad del dispositivo)
- PhotosUI (PhotosPicker para galería)

### Integraciones
- **Gemini 2.5 Flash**: OCR para detección de alias
- **API Local**: Validación de alias y obtención de token (FastAPI en localhost:8000)
- **API Stage Ualá**: Validación real de alias (próximamente)

### Gestión de Token
- Token almacenado en UserDefaults
- Refresh automático al volver a primer plano (`scenePhase`)
- Retry automático en errores 401/403 (máximo 1 reintento)
- Endpoint local `/token` que obtiene token de gcloud

### UI/UX
- Diseño inspirado en apps fintech (estilo Ualá)
- Transiciones fluidas con Spring animations
- Sin rectángulo de escaneo visible
- Color principal: Azul Ualá (#4A3AFF)

## Flujo de Usuario

```
[Home]
    ↓
[Tap Scanner (centro)]
    ↓
[ContentView - Scanner activo]
    ↓
┌─────────────────────────────────────┐
│  Detección automática:              │
│  • QR → delay 1s → PaymentView QR   │
│  • Barcode → delay 1s → PaymentView │
│  • Alias → validar → TransferFlow   │
│  • QR+Barcode → Menú selección      │
└─────────────────────────────────────┘
    ↓
[PaymentView o TransferFlow]
    ↓
[Confirmar]
    ↓
[SuccessView]
    ↓
[Genial → Home]
```

## Permisos Requeridos
- Cámara (AVCaptureDevice)
- Acceso a fotos (PhotosPicker - no requiere permiso explícito)

## Configuración

### API Local
```bash
cd mock_db && python3 api.py
```
- Puerto: 8000
- Endpoints: `/validate/{alias}`, `/token`, `/search/{query}`

### IP de Red
Actualizar en `Config.swift`:
```swift
static let localAPIUrl = "http://<TU_IP>:8000"
```

## Versión
- v2.0 - Scanner con Vision Framework, multi-code detection, token auto-refresh
