# AliasDetector - Product Requirements Document

## Descripción General
App iOS nativa para realizar transferencias bancarias mediante alias CBU/CVU, con scanner inteligente que detecta automáticamente alias, códigos QR y facturas de servicios usando IA (Gemini 2.5 Flash).

## Funcionalidades Principales

### 1. Validación de Alias
- Input para ingresar alias CBU/CVU
- Validación contra API mock local
- Muestra datos del destinatario:
  - Nombre completo
  - Banco/Entidad
  - Tipo de cuenta

### 2. Smart Scanner (Detección Inteligente)
El scanner unificado detecta automáticamente tres tipos de contenido:

#### 2.1 Detección de Alias CBU/CVU
- Escaneo continuo de la cámara
- Detección automática de alias en formato `palabra.palabra.palabra`
- Validación contra API local
- Muestra datos del destinatario y permite transferir

#### 2.2 Detección de Código QR
- Identifica códigos QR en la imagen
- Muestra landing "QR - próximamente"
- Preparado para futura implementación de pago por QR

#### 2.3 Detección de Facturas de Servicios
- Reconoce facturas de: luz, gas, agua, teléfono, internet, expensas, cable
- Muestra landing "Pago de servicios - próximamente"
- Preparado para futura implementación de pago de servicios

### 3. Flujo de Transferencia

#### 3.1 Pantalla de Monto
- Display de monto con formato argentino:
  - Separador de miles: punto (.)
  - Decimales en superíndice (más pequeños)
  - Ejemplo: $1.500^50
- Montos rápidos predefinidos: $100, $5.000, $10.000
- Teclado numérico para ingreso manual
- Indicador de dinero disponible

#### 3.2 Escaneo de Tickets/Imágenes
- **Cámara**: Captura directa de tickets/facturas
- **Galería**: Selección de imágenes desde el carrete (PhotosPicker)
- Detección automática de monto usando Gemini AI
- Fuentes de imagen soportadas:
  - Tickets de compra
  - Facturas
  - Capturas de chat (ej: "me debés $X")
  - Pantallas de POS/Posnet
  - Menús de restaurantes
  - Etiquetas de precio
  - Boletas de servicios (luz, gas, expensas)
  - Presupuestos
  - Notas manuscritas
  - Capturas de apps (MercadoPago, Rappi, etc.)
- Monto exacto sin redondeo
- Loading spinner durante el procesamiento
- Detección automática de categoría con animación visual (sparkles)

#### 3.3 Categorización
- Categorías disponibles:
  - Comida, Restaurantes, Transporte, Servicios
  - Alquiler, Salud, Entretenimiento, Compras
  - Educación, Suscripciones, Hogar, Otros
- Selector visual con emojis
- Auto-detección desde el análisis de imagen

#### 3.4 Confirmación
- Transición suave desde pantalla de monto (matchedGeometryEffect)
- Detalles mostrados:
  - Nombre del destinatario
  - Entidad bancaria
  - Concepto/Motivo
  - Tiempo de llegada
- Botón de confirmación

#### 3.5 Pantalla de Éxito
- Animación de celebración:
  - Confetti multicolor
  - Emojis animados
  - Checkmark con pulso
- Haptic feedback
- Resumen de la transferencia
- Botón para finalizar

## Especificaciones Técnicas

### Stack
- SwiftUI (iOS 17+)
- AVFoundation (cámara)
- PhotosUI (PhotosPicker para galería)
- URLSession para API calls

### Integraciones
- **Gemini 2.5 Flash**: OCR y análisis de imágenes para extracción de montos
- **API Mock Local**: Validación de alias (FastAPI en localhost:8000)

### UI/UX
- Diseño inspirado en apps fintech (estilo Ualá/DolarApp)
- Transiciones fluidas con Spring animations
- Layout adaptativo con GeometryReader
- Color principal: Azul Ualá (#4A3AFF)

## Flujo de Usuario

```
[Inicio]
    ↓
[Ingresar Alias] → [Validar] → [Ver datos destinatario]
    ↓
[Ingresar Monto]
    ├── Manual (teclado)
    ├── Monto rápido ($100, $5K, $10K)
    └── Escanear imagen
         ├── Tomar foto (cámara)
         └── Elegir de galería
    ↓
[Seleccionar Categoría] (opcional/auto-detectada)
    ↓
[Confirmar Transferencia]
    ↓
[Éxito + Celebración]
```

## Permisos Requeridos
- Cámara (AVCaptureDevice)
- Acceso a fotos (PhotosPicker - no requiere permiso explícito)

## Versión
- v1.0 - Funcionalidad completa de transferencias con escaneo inteligente
