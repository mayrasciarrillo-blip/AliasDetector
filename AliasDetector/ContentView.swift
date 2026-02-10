import SwiftUI
import UIKit

// MARK: - Menú de selección de código (cuando hay múltiples)
struct CodeSelectionMenu: View {
    let codes: [DetectedCode]
    let onSelect: (DetectedCode) -> Void
    let onCancel: () -> Void

    private let accentColor = Color(red: 0.25, green: 0.20, blue: 0.95)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                // Header
                Text("¿Qué querés pagar?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                // Botones para cada tipo de código detectado
                ForEach(codes) { code in
                    Button(action: { onSelect(code) }) {
                        HStack(spacing: 12) {
                            Image(systemName: code.type == .qr ? "qrcode" : "barcode")
                                .font(.system(size: 24))
                            Text(code.type == .qr ? "Pagar con QR" : "Pagar con Código de Barras")
                                .font(.system(size: 17, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }

                // Botón cancelar
                Button(action: onCancel) {
                    Text("Cancelar")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -5)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
}

// Fantasma animado para estado "no encontrado"
struct GhostView: View {
    @State private var float = false
    @State private var lookAround = false
    @State private var tailWiggle = false

    var body: some View {
        ZStack {
            // Sombra
            Ellipse()
                .fill(Color.black.opacity(0.08))
                .frame(width: 50, height: 14)
                .offset(y: 55)
                .scaleEffect(float ? 0.7 : 1.0)

            // Fantasma
            ZStack {
                // Cuerpo principal
                VStack(spacing: 0) {
                    // Cabeza redondeada
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color(red: 0.92, green: 0.92, blue: 0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 65)

                    // Cola ondulada
                    GhostTailShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.92, green: 0.92, blue: 0.95), Color(red: 0.85, green: 0.85, blue: 0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 30)
                        .offset(y: -8)
                        .scaleEffect(x: tailWiggle ? 1.05 : 0.95)
                }

                // Cara
                VStack(spacing: 6) {
                    // Ojos
                    HStack(spacing: 16) {
                        GhostEye(lookRight: lookAround)
                        GhostEye(lookRight: lookAround)
                    }

                    // Boca (O de sorpresa)
                    Ellipse()
                        .fill(Color(red: 0.3, green: 0.3, blue: 0.35))
                        .frame(width: 12, height: 16)
                }
                .offset(y: -12)

                // Rubor
                HStack(spacing: 36) {
                    Circle()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
                .offset(y: -4)
            }
            .offset(y: float ? -10 : 0)
        }
        .frame(width: 100, height: 130)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                float = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                lookAround = true
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                tailWiggle = true
            }
        }
    }
}

// Ojo del fantasma
struct GhostEye: View {
    let lookRight: Bool

    var body: some View {
        ZStack {
            // Ojo blanco
            Ellipse()
                .fill(Color.white)
                .frame(width: 18, height: 20)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

            // Pupila
            Circle()
                .fill(Color(red: 0.2, green: 0.2, blue: 0.25))
                .frame(width: 10, height: 10)
                .offset(x: lookRight ? 3 : -3, y: 2)
        }
    }
}

// Forma de la cola del fantasma
struct GhostTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))

        // Ondas en la parte inferior
        path.addLine(to: CGPoint(x: w, y: h * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.75, y: h),
            control: CGPoint(x: w * 0.9, y: h * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.6),
            control: CGPoint(x: w * 0.6, y: h)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.25, y: h),
            control: CGPoint(x: w * 0.4, y: h)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.5),
            control: CGPoint(x: w * 0.1, y: h * 0.3)
        )

        path.closeSubpath()
        return path
    }
}

// Rectángulo blanco estático (estado idle - guía para posicionar)
struct IdleRect: View {
    let width: CGFloat = 280
    let height: CGFloat = 100

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: width, height: height)

            // Esquinas destacadas
            ForEach(0..<4) { corner in
                CornerShape(corner: corner)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
    }
}

// Rectángulo con matriz de puntos animados (estado analizando)
struct AnalyzingRect: View {
    let width: CGFloat = 280
    let height: CGFloat = 100

    let columns = 12
    let rows = 4

    @State private var activeDots: Set<Int> = []
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Borde blanco
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: width, height: height)

            // Esquinas destacadas
            ForEach(0..<4) { corner in
                CornerShape(corner: corner)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: width, height: height)
            }

            // Matriz de puntos
            let dotSpacingX = (width - 60) / CGFloat(columns - 1)
            let dotSpacingY = (height - 40) / CGFloat(rows - 1)

            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { col in
                    let index = row * columns + col
                    Circle()
                        .fill(activeDots.contains(index) ? Color.white : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                        .position(
                            x: 30 + CGFloat(col) * dotSpacingX,
                            y: 20 + CGFloat(row) * dotSpacingY
                        )
                        .animation(.easeInOut(duration: 0.15), value: activeDots.contains(index))
                }
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            // Elegir entre 3 y 8 puntos aleatorios para encender
            let totalDots = columns * rows
            var newActive: Set<Int> = []
            let count = Int.random(in: 3...8)
            for _ in 0..<count {
                newActive.insert(Int.random(in: 0..<totalDots))
            }
            activeDots = newActive
        }
    }
}

// Rectángulo verde (estado encontrado)
struct FoundRect: View {
    let width: CGFloat = 280
    let height: CGFloat = 100

    @State private var isGlowing = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green, lineWidth: 3)
                .frame(width: width, height: height)
                .shadow(color: Color.green.opacity(isGlowing ? 0.8 : 0.4), radius: isGlowing ? 12 : 6)

            // Esquinas destacadas en verde
            ForEach(0..<4) { corner in
                CornerShape(corner: corner)
                    .stroke(Color.green, lineWidth: 4)
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

// Forma para las esquinas
struct CornerShape: Shape {
    let corner: Int
    let length: CGFloat = 25

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch corner {
        case 0: // Top-left
            path.move(to: CGPoint(x: 0, y: length))
            path.addLine(to: CGPoint(x: 0, y: 12))
            path.addQuadCurve(to: CGPoint(x: 12, y: 0), control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: length, y: 0))
        case 1: // Top-right
            path.move(to: CGPoint(x: rect.width - length, y: 0))
            path.addLine(to: CGPoint(x: rect.width - 12, y: 0))
            path.addQuadCurve(to: CGPoint(x: rect.width, y: 12), control: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: length))
        case 2: // Bottom-right
            path.move(to: CGPoint(x: rect.width, y: rect.height - length))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - 12))
            path.addQuadCurve(to: CGPoint(x: rect.width - 12, y: rect.height), control: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - length, y: rect.height))
        case 3: // Bottom-left
            path.move(to: CGPoint(x: length, y: rect.height))
            path.addLine(to: CGPoint(x: 12, y: rect.height))
            path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - 12), control: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - length))
        default:
            break
        }

        return path
    }
}

// Modelo para datos del alias validado
struct AliasData {
    let alias: String
    let tipo: String
    let entidad: String
    let nombreCompleto: String
    let cuitCuil: String
    let cvu: String
    let bankId: String
}

// Vista de confetti
struct ConfettiView: View {
    let colors: [Color] = [
        Color(red: 0.29, green: 0.23, blue: 1.0),      // Azul Ualá principal
        Color(red: 0.29, green: 0.23, blue: 1.0),      // Azul Ualá (más frecuente)
        Color(red: 0.4, green: 0.35, blue: 1.0),       // Azul Ualá claro
        Color(red: 0.2, green: 0.15, blue: 0.8),       // Azul Ualá oscuro
        Color(red: 0.55, green: 0.5, blue: 1.0),       // Lavanda
        Color.white,                                    // Blanco
        Color(red: 0.95, green: 0.95, blue: 1.0)       // Blanco azulado
    ]

    @State private var particles: [(id: Int, color: Color, x: CGFloat, delay: Double, size: CGFloat)] = []
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    ConfettiParticleView(
                        color: particle.color,
                        startX: particle.x,
                        delay: particle.delay,
                        screenHeight: geo.size.height,
                        particleSize: particle.size,
                        animate: animate
                    )
                }
            }
            .onAppear {
                // Generar muchas partículas
                for i in 0..<60 {
                    particles.append((
                        id: i,
                        color: colors.randomElement()!,
                        x: CGFloat.random(in: 0...geo.size.width),
                        delay: Double.random(in: 0...0.5),
                        size: CGFloat.random(in: 8...14)
                    ))
                }
                // Iniciar animación inmediatamente
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiParticleView: View {
    let color: Color
    let startX: CGFloat
    let delay: Double
    let screenHeight: CGFloat
    let particleSize: CGFloat
    let animate: Bool

    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    @State private var scale: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: particleSize, height: particleSize)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(position)
            .onAppear {
                position = CGPoint(x: startX, y: -20)
                // Iniciar animación si ya está activa
                if animate {
                    startAnimation()
                }
            }
            .onChange(of: animate) { _, newValue in
                if newValue {
                    startAnimation()
                }
            }
    }

    private func startAnimation() {
        withAnimation(.easeOut(duration: 2.5).delay(delay)) {
            position = CGPoint(
                x: startX + CGFloat.random(in: -80...80),
                y: screenHeight + 50
            )
            rotation = Double.random(in: 360...1080)
            opacity = 0
            scale = 0.2
        }
    }
}

// Color Ualá
let ualaBlue = Color(red: 0.29, green: 0.23, blue: 1.0)

// Bottom Sheet estilo Ualá
struct ResultBottomSheet: View {
    let resultText: String
    let aliasData: AliasData?
    let aliasValidated: Bool
    let onScanAgain: () -> Void
    let onTransfer: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if let data = aliasData {
                        // Verificado
                        ZStack {
                            Circle()
                                .fill(ualaBlue.opacity(0.1))
                                .frame(width: 72, height: 72)
                            Image(systemName: "checkmark")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(ualaBlue)
                        }
                        .padding(.top, 24)

                        Text("Alias verificado")
                            .font(.system(size: 20, weight: .bold))

                        // Card datos
                        VStack(spacing: 0) {
                            DataRow(label: "Alias", value: data.alias)
                            Divider().padding(.horizontal, 16)
                            DataRow(label: "Titular", value: data.nombreCompleto)
                            Divider().padding(.horizontal, 16)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Entidad")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 8) {
                                        Text(data.entidad)
                                            .font(.system(size: 15, weight: .medium))
                                        Text(data.tipo)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(ualaBlue)
                                            .cornerRadius(6)
                                    }
                                }
                                Spacer()
                            }
                            .padding(16)
                            Divider().padding(.horizontal, 16)
                            DataRow(label: "CUIT/CUIL", value: data.cuitCuil)
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)

                    } else if aliasValidated {
                        // No registrado - Estado lúdico con fantasma
                        GhostView()
                            .padding(.top, 8)

                        Text("¡Buuu! No lo encontré")
                            .font(.system(size: 20, weight: .bold))

                        Text("Este alias es un fantasma 👻")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Buscamos")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Text(resultText)
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)

                            Divider().padding(.horizontal, 16)

                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Probá escribir el alias en un papel con letra clara y volvé a escanearlo.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)

                    } else {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(ualaBlue)
                            .padding(.top, 40)
                        Text("Haciendo magia ✨")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 12)
                        Text(resultText)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            }

            // Botones
            VStack(spacing: 12) {
                if aliasData != nil {
                    Button(action: onTransfer) {
                        Text("Transferir a esta cuenta")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(ualaBlue)
                            .cornerRadius(12)
                    }
                    Button(action: onScanAgain) {
                        Text("Volver a intentarlo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ualaBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ualaBlue, lineWidth: 1.5))
                    }
                } else {
                    Button(action: onScanAgain) {
                        Text("Volver a intentarlo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(ualaBlue)
                            .cornerRadius(12)
                    }
                    Button(action: {}) {
                        Text("Ingresar alias manualmente")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ualaBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ualaBlue, lineWidth: 1.5))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Color.white)
        .onAppear {
            if aliasData != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// Fila de datos estilo Ualá
struct DataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
            }
            Spacer()
        }
        .padding(16)
    }
}

struct ContentView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isAnalyzing = false
    @State private var aliasFound = false
    @State private var aliasValidated = false
    @State private var resultText: String = ""
    @State private var statusMessage: String = "Posicioná el alias, QR o código de barras en el centro de la pantalla"
    @State private var isValidatingAlias = false
    @State private var aliasData: AliasData?
    @State private var showConfetti = false
    @State private var showTransferFlow = false
    @State private var showQRLanding = false
    @State private var showBarcodeLanding = false
    @State private var detectedCodes: [DetectedCode] = []  // Códigos detectados para selección

    var body: some View {
        ZStack {
            // Camera preview con Vision integrado
            CameraView(capturedImage: .constant(nil), onScanResult: { result in
                print("📷 onScanResult: \(result)")
                guard !isAnalyzing && !aliasFound && !showQRLanding && !showBarcodeLanding && detectedCodes.isEmpty else {
                    print("📷 BLOQUEADO - isAnalyzing:\(isAnalyzing) aliasFound:\(aliasFound)")
                    return
                }

                switch result {
                case .qrCode:
                    // QR detectado → delay de 1 segundo antes de mostrar landing
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showQRLanding = true
                    }

                case .barcode:
                    // Barcode detectado → delay de 1 segundo antes de mostrar landing
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showBarcodeLanding = true
                    }

                case .multipleCodes(let codes):
                    // Múltiples códigos detectados → mostrar overlays para selección
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    detectedCodes = codes
                    statusMessage = "Tocá el código que querés escanear"

                case .needsOCR(let image):
                    // Sin QR/barcode, enviar a Gemini para OCR de alias
                    analyzeImageForAlias(image)

                case .nothing:
                    break
                }
            })
            .ignoresSafeArea()

            VStack {
                // Status pill
                HStack(spacing: 10) {
                    if isAnalyzing {
                        // Procesando con AI: sparkles + spinner
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    } else if isValidatingAlias {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    Text(statusMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.6))
                .cornerRadius(24)
                .padding(.top, 60)
                .opacity(isValidatingAlias || isAnalyzing || !aliasFound ? 1 : 0)

                Spacer()
            }

            // Menú de selección cuando hay múltiples códigos
            if !detectedCodes.isEmpty {
                CodeSelectionMenu(
                    codes: detectedCodes,
                    onSelect: { code in
                        selectCode(code)
                    },
                    onCancel: {
                        detectedCodes = []
                        statusMessage = "Posicioná el alias, QR o código de barras en el centro de la pantalla"
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Confetti fullscreen
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: Binding(
            get: { aliasFound && !resultText.isEmpty && !showTransferFlow },
            set: { if !$0 { resetScan() } }
        )) {
            ResultBottomSheet(
                resultText: resultText,
                aliasData: aliasData,
                aliasValidated: aliasValidated,
                onScanAgain: resetScan,
                onTransfer: {
                    showTransferFlow = true
                }
            )
            .presentationDetents([.height(600), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .interactiveDismissDisabled(false)
        }
        .fullScreenCover(isPresented: $showTransferFlow) {
            if let data = aliasData {
                TransferFlowView(
                    aliasData: data,
                    onCancel: {
                        showTransferFlow = false
                    },
                    onComplete: {
                        showTransferFlow = false
                        resetScan()
                        dismiss()  // Volver a home
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showQRLanding, onDismiss: resetScan) {
            PaymentView(paymentType: .qr, onGoHome: { dismiss() })
        }
        .fullScreenCover(isPresented: $showBarcodeLanding, onDismiss: resetScan) {
            PaymentView(paymentType: .barcode, onGoHome: { dismiss() })
        }
        .onAppear {
            let token = Config.geminiToken
            print("🚀 Scanner abierto - Gemini token: \(token.isEmpty ? "VACÍO" : "OK (\(token.prefix(20))...)")")
            if token.isEmpty {
                print("🔄 Intentando obtener token de Gemini...")
                Task {
                    let ok = await Config.refreshToken()
                    print("🔄 Refresh Gemini token: \(ok ? "OK ✅" : "FALLÓ ❌ (servidor local no disponible)")")
                }
            }
            // También pre-autenticar Stage
            Task { await StageAuthService.shared.ensureValidToken() }
        }
    }

    private func resetScan() {
        aliasFound = false
        aliasValidated = false
        isValidatingAlias = false
        resultText = ""
        aliasData = nil
        showConfetti = false
        showQRLanding = false
        showBarcodeLanding = false
        detectedCodes = []
        statusMessage = "Posicioná el alias, QR o código de barras en el centro de la pantalla"
    }

    private func selectCode(_ code: DetectedCode) {
        detectedCodes = []  // Limpiar selección
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if code.type == .qr {
                showQRLanding = true
            } else {
                showBarcodeLanding = true
            }
        }
    }

    // Análisis de imagen solo para alias (QR y barcodes ya se detectan con Vision)
    private func analyzeImageForAlias(_ image: UIImage, retryCount: Int = 0) {
        let maxRetries = 1  // Solo 1 reintento después de refrescar token
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            return
        }

        isAnalyzing = true
        statusMessage = "Procesando la imagen"

        let token = Config.geminiToken
        print("📸 Enviando imagen a Gemini (token: \(token.isEmpty ? "VACÍO ⚠️" : "\(token.prefix(20))..."))")

        // Pre-autenticar con Stage en paralelo con Gemini OCR
        Task { await StageAuthService.shared.ensureValidToken() }

        // Si no hay token, intentar refrescar primero
        if token.isEmpty {
            print("⚠️ Token vacío, intentando refrescar...")
            Task {
                let refreshed = await Config.refreshToken()
                print("🔄 Refresh result: \(refreshed), nuevo token: \(Config.geminiToken.isEmpty ? "VACÍO" : "OK")")
                if !refreshed {
                    await MainActor.run {
                        isAnalyzing = false
                        statusMessage = "Sin conexión al servidor de tokens"
                    }
                    return
                }
                // Reintentar con el token nuevo
                await MainActor.run {
                    self.analyzeImageForAlias(image, retryCount: retryCount)
                }
            }
            return
        }

        let url = URL(string: Config.geminiAPIUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15  // Timeout más corto

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        func append(_ str: String) {
            body.append(str.data(using: .utf8)!)
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        append("gemini-2.5-flash\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n")
        append("0.0\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"system_prompt\"\r\n\r\n")
        append("Sos un OCR. Respondé breve.\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"user_prompt\"\r\n\r\n")
        // Prompt simplificado - solo buscar alias
        append("Buscá un alias CBU/CVU en la imagen (formato palabra.palabra, 6-20 caracteres, solo letras/números/puntos). Si lo encontrás, respondé SOLO el alias. Si no hay alias, respondé NO_ALIAS.\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"files\"; filename=\"photo.jpg\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        append("\r\n--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isAnalyzing = false

                let defaultMessage = "Posicioná el alias, QR o código de barras en el centro de la pantalla"

                if let error = error {
                    print("❌ Gemini request error: \(error.localizedDescription)")
                    statusMessage = defaultMessage
                    return
                }

                if let http = response as? HTTPURLResponse {
                    print("📡 Gemini response status: \(http.statusCode)")
                }

                // Si el token expiró (401/403), refrescar y reintentar (máximo 1 vez)
                if let http = response as? HTTPURLResponse,
                   (http.statusCode == 401 || http.statusCode == 403) {
                    if retryCount < maxRetries {
                        Task {
                            let refreshed = await Config.refreshToken()
                            if refreshed {
                                print("🔄 Token refrescado, reintentando... (intento \(retryCount + 1))")
                                DispatchQueue.main.async {
                                    self.analyzeImageForAlias(image, retryCount: retryCount + 1)
                                }
                            } else {
                                print("❌ No se pudo refrescar el token")
                                DispatchQueue.main.async {
                                    self.statusMessage = defaultMessage
                                }
                            }
                        }
                    } else {
                        print("❌ Token inválido después de \(maxRetries) reintentos")
                        statusMessage = defaultMessage
                    }
                    return
                }

                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200,
                      let data = data else {
                    statusMessage = defaultMessage
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let resp = json["response"] as? String {

                    print("🔍 Gemini raw: \"\(resp)\"")
                    let lower = resp.lowercased()

                    if lower.contains("no_alias") || lower.contains("no alias") ||
                       lower.contains("no detectado") || lower.contains("no puedo") ||
                       lower.contains("no veo") || lower.contains("no hay") {
                        statusMessage = defaultMessage
                    } else {
                        // Extraer el alias del texto
                        let aliasCandidate = extractAlias(from: resp)
                        print("🔍 extractAlias: \"\(aliasCandidate)\"")
                        if aliasCandidate.count >= 6 {
                            aliasFound = true
                            resultText = aliasCandidate
                            isValidatingAlias = true
                            statusMessage = "Validando alias ✨"
                            validateAlias(aliasCandidate)
                        } else {
                            statusMessage = defaultMessage
                        }
                    }
                } else {
                    statusMessage = defaultMessage
                }
            }
        }.resume()
    }

    private func extractAlias(from text: String) -> String {
        // Alias CBU: 6-20 chars, solo a-z, 0-9 y punto (.) como separador
        let pattern = #"[a-z][a-z0-9]*(\.[a-z0-9]+)+"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let alias = String(text[range]).lowercased()
            // Validar longitud 6-20
            if alias.count >= 6 && alias.count <= 20 {
                return alias
            }
        }
        // Si no encuentra patrón válido, limpiar y devolver
        let cleaned = text
            .lowercased()
            .components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.").inverted)
            .joined()
        // Validar longitud
        if cleaned.count >= 6 && cleaned.count <= 20 {
            return cleaned
        }
        return cleaned.isEmpty ? text.lowercased() : cleaned
    }

    private func validateAlias(_ alias: String) {
        Task {
            let result = await StageAliasService.shared.validateAlias(alias)
            await MainActor.run {
                aliasValidated = true
                isValidatingAlias = false

                switch result {
                case .success(let info):
                    showConfetti = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    let tipo: String
                    if let cvu = info.cvu, !cvu.isEmpty {
                        tipo = "CVU"
                    } else {
                        tipo = "CBU"
                    }

                    aliasData = AliasData(
                        alias: info.alias ?? alias,
                        tipo: tipo,
                        entidad: info.displayBank,
                        nombreCompleto: info.displayName,
                        cuitCuil: info.cuil ?? "?",
                        cvu: info.cvu ?? "",
                        bankId: info.bankID ?? ""
                    )

                case .failure(let error):
                    print("❌ Alias validation failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
