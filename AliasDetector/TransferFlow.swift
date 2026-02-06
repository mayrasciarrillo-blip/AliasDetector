import SwiftUI
import UIKit

// MARK: - Formatted Amount View (con decimales en superíndice)
struct FormattedAmountView: View {
    let amount: String
    let integerFontSize: CGFloat
    let decimalFontSize: CGFloat
    let color: Color

    init(amount: String, fontSize: CGFloat = 44, color: Color = .primary) {
        self.amount = amount
        self.integerFontSize = fontSize
        self.decimalFontSize = fontSize * 0.45
        self.color = color
    }

    var formattedParts: (integer: String, decimal: String) {
        let cleanAmount = amount.replacingOccurrences(of: ",", with: ".")
        let number = Double(cleanAmount) ?? 0

        // Separar parte entera y decimal
        let integerPart = Int(number)
        let decimalPart = Int(round((number - Double(integerPart)) * 100))

        // Formatear parte entera con separador de miles (punto)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.maximumFractionDigits = 0
        let integerStr = formatter.string(from: NSNumber(value: integerPart)) ?? "\(integerPart)"

        // Formatear decimales con dos dígitos
        let decimalStr = String(format: "%02d", decimalPart)

        return (integerStr, decimalStr)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            Text("$")
                .font(.system(size: integerFontSize, weight: .bold))
                .foregroundColor(color)

            Text(formattedParts.integer)
                .font(.system(size: integerFontSize, weight: .bold))
                .foregroundColor(color)

            Text(formattedParts.decimal)
                .font(.system(size: decimalFontSize, weight: .semibold))
                .foregroundColor(color.opacity(0.7))
                .baselineOffset(integerFontSize * 0.45)
        }
    }
}

// MARK: - Transfer Flow Container
struct TransferFlowView: View {
    let aliasData: AliasData
    let onCancel: () -> Void
    let onComplete: () -> Void

    @State private var currentStep: TransferStep = .amount
    @State private var amount: String = ""
    @State private var motivo: String = "Varios"
    @State private var isProcessing = false
    @Namespace private var animation

    enum TransferStep {
        case amount
        case confirmation
        case success
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if currentStep == .success {
                TransferSuccessView(
                    aliasData: aliasData,
                    amount: amount,
                    onDone: onComplete
                )
                .transition(.opacity)
            } else {
                // Vista unificada para amount y confirmation
                UnifiedTransferView(
                    aliasData: aliasData,
                    amount: $amount,
                    motivo: $motivo,
                    currentStep: $currentStep,
                    isProcessing: $isProcessing,
                    animation: animation,
                    onCancel: onCancel,
                    onConfirm: processTransfer
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
    }

    private func processTransfer() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isProcessing = false
            currentStep = .success
        }
    }
}

// MARK: - Unified Transfer View (Amount + Confirmation en una sola vista)
struct UnifiedTransferView: View {
    let aliasData: AliasData
    @Binding var amount: String
    @Binding var motivo: String
    @Binding var currentStep: TransferFlowView.TransferStep
    @Binding var isProcessing: Bool
    var animation: Namespace.ID
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @FocusState private var isAmountFocused: Bool
    @State private var showMotivoSheet = false
    @State private var showCamera = false
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var categoryJustLoaded = false

    let categorias: [(emoji: String, nombre: String)] = [
        ("🍔", "Comida"), ("🍽️", "Restaurantes"), ("🚗", "Transporte"),
        ("💡", "Servicios"), ("🏠", "Alquiler"), ("💊", "Salud"),
        ("🎬", "Entretenimiento"), ("🛍️", "Compras"), ("📚", "Educación"),
        ("📱", "Suscripciones"), ("🛋️", "Hogar"), ("📦", "Otros")
    ]

    var numericAmount: Double {
        Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var isConfirmation: Bool {
        currentStep == .confirmation
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header fijo arriba
                headerView
                    .padding(.top, 16)

                // Contenido central que se adapta
                VStack(spacing: 0) {
                    Spacer()

                    amountDisplayView

                    if isConfirmation {
                        confirmationDetails
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        inputControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer()
                }
                .frame(height: geo.size.height - 160) // Resta espacio de header y botón

                // Botón fijo abajo
                actionButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showMotivoSheet) {
            CategoriaPickerSheet(
                selectedCategoria: $motivo,
                categorias: categorias,
                onDismiss: { showMotivoSheet = false }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                scanAmountFromImage(image)
            }
        }
        .onChange(of: isConfirmation) { _, newValue in
            if newValue {
                isAmountFocused = false
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                if isConfirmation {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .amount
                    }
                } else {
                    onCancel()
                }
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isProcessing ? .clear : .primary)
            }
            .disabled(isProcessing)

            Spacer()

            VStack(spacing: 2) {
                Text("Para: \(aliasData.nombreCompleto.components(separatedBy: " ").first ?? "")")
                    .font(.system(size: 16, weight: .semibold))
                Text(aliasData.alias)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Placeholder para balance
            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Amount Display
    private var amountDisplayView: some View {
        VStack(spacing: 12) {
            if isScanning {
                // Loading mientras escanea
                HStack(alignment: .center, spacing: 8) {
                    Text("$")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.gray.opacity(0.3))
                    ProgressView()
                        .scaleEffect(1.8)
                        .frame(width: 60)
                }
            } else if amount.isEmpty && !isConfirmation {
                // Placeholder
                HStack(alignment: .top, spacing: 2) {
                    Text("$")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("0")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("00")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.2))
                        .baselineOffset(25)
                }
                .onTapGesture { isAmountFocused = true }
            } else {
                FormattedAmountView(amount: amount.isEmpty ? "0" : amount, fontSize: 56)
                    .matchedGeometryEffect(id: "amount", in: animation)
                    .onTapGesture {
                        if !isConfirmation {
                            isAmountFocused = true
                        }
                    }
            }

            if !isConfirmation {
                // Subtítulo según estado
                if isScanning {
                    Text("Leyendo monto del ticket...")
                        .font(.system(size: 14))
                        .foregroundColor(ualaBlue)
                } else if let error = scanError {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                } else {
                    HStack(spacing: 6) {
                        Text("Dinero disponible:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        FormattedAmountView(amount: "50000", fontSize: 14, color: .secondary)
                    }
                }

                // TextField invisible
                TextField("", text: $amount)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .opacity(0)
                    .frame(width: 1, height: 1)
            }
        }
    }

    // MARK: - Input Controls
    private var inputControls: some View {
        VStack(spacing: 16) {
            // Montos rápidos
            HStack(spacing: 10) {
                ForEach([("100", "100"), ("5.000", "5000"), ("10.000", "10000")], id: \.0) { display, value in
                    Button(action: {
                        amount = value
                        scanError = nil
                    }) {
                        Text("$\(display)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                Button(action: { showCamera = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 14))
                        Text("Ticket")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(ualaBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ualaBlue.opacity(0.1))
                    )
                }
            }

            // Categoría
            Button(action: { showMotivoSheet = true }) {
                HStack(spacing: 6) {
                    Text("Categoría:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    if let cat = categorias.first(where: { $0.nombre == motivo }) {
                        HStack(spacing: 4) {
                            Text("\(cat.emoji) \(cat.nombre)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(categoryJustLoaded ? ualaBlue : .primary)

                            if categoryJustLoaded {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                    .foregroundColor(ualaBlue)
                            }
                        }
                        .padding(.horizontal, categoryJustLoaded ? 8 : 0)
                        .padding(.vertical, categoryJustLoaded ? 4 : 0)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(categoryJustLoaded ? ualaBlue.opacity(0.1) : Color.clear)
                        )
                        .scaleEffect(categoryJustLoaded ? 1.05 : 1.0)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: categoryJustLoaded)
        }
        .padding(.top, 30)
    }

    // MARK: - Confirmation Details
    private var confirmationDetails: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ConfirmationRow(label: "Nombre del destinatario", value: aliasData.nombreCompleto)
                Divider().padding(.horizontal, 16)
                ConfirmationRow(label: "Entidad", value: "\(aliasData.entidad)")
                Divider().padding(.horizontal, 16)
                ConfirmationRow(label: "Concepto", value: motivo)
                Divider().padding(.horizontal, 16)
                ConfirmationRow(label: "Llegada", value: "⚡ Al instante")
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.top, 40)
        }
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            if isConfirmation {
                onConfirm()
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep = .confirmation
                }
            }
        }) {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isProcessing ? "Enviando..." : (isConfirmation ? "Confirmar y enviar" : "Continuar"))
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(numericAmount > 0 || isConfirmation ? .white : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isProcessing ? Color.gray :
                    (numericAmount > 0 || isConfirmation ? ualaBlue : Color.gray.opacity(0.15))
            )
            .cornerRadius(12)
        }
        .disabled((numericAmount <= 0 && !isConfirmation) || isProcessing)
    }

    // MARK: - Scan Amount
    private func scanAmountFromImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            scanError = "Error al procesar la imagen"
            return
        }

        isScanning = true
        scanError = nil
        isAmountFocused = false

        let url = URL(string: Config.geminiAPIUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.geminiToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

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
        append("Sos un experto en extraer montos de cualquier tipo de imagen. Podés leer tickets, facturas, capturas de pantalla de chats o apps, pantallas de terminales de pago, menús, etiquetas de precio, boletas de servicios, presupuestos, notas manuscritas y cualquier imagen que contenga un monto a pagar.\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"user_prompt\"\r\n\r\n")
        append("Analizá esta imagen y extraé el monto a pagar. Puede ser: ticket, factura, captura de chat (ej: 'me debés $X'), pantalla de POS/Posnet, menú de restaurante, etiqueta de precio, resumen de tarjeta, boleta de servicios (luz, gas, expensas), presupuesto, nota manuscrita, captura de app (MercadoPago, Rappi, etc), o cualquier imagen con un monto. Extraé: 1) El monto TOTAL o principal visible. 2) La categoría. Categorías: Comida, Restaurantes, Transporte, Servicios, Alquiler, Salud, Entretenimiento, Compras, Educación, Suscripciones, Hogar, Otros. Formato de respuesta: MONTO|CATEGORIA. Incluí centavos con punto (ej: 1500.50). NO redondees, usá el monto EXACTO. Ejemplos: 1500.00|Servicios, 350.99|Comida. Si no hay monto claro: NO_MONTO|Otros\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"files\"; filename=\"ticket.jpg\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        append("\r\n--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isScanning = false

                if error != nil {
                    scanError = "Error de conexión"
                    return
                }

                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200,
                      let data = data else {
                    scanError = "Error al analizar"
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let resp = json["response"] as? String {

                    let cleaned = resp.trimmingCharacters(in: .whitespacesAndNewlines)
                    let parts = cleaned.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }

                    var amountPart = (parts.first ?? "")
                        .replacingOccurrences(of: "$", with: "")
                        .replacingOccurrences(of: " ", with: "")

                    if amountPart.contains(",") {
                        amountPart = amountPart
                            .replacingOccurrences(of: ".", with: "")
                            .replacingOccurrences(of: ",", with: ".")
                    }

                    let categoryPart = parts.count > 1 ? parts[1] : "Varios"

                    if amountPart.lowercased().contains("no_monto") || amountPart.isEmpty {
                        scanError = "No encontré un monto en la imagen"
                    } else if Double(amountPart) != nil {
                        amount = amountPart

                        let categoriasValidas = categorias.map { $0.nombre }
                        if categoriasValidas.contains(categoryPart) {
                            motivo = categoryPart
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                categoryJustLoaded = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    categoryJustLoaded = false
                                }
                            }
                        }

                        scanError = nil
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } else {
                        scanError = "No pude leer el monto"
                    }
                } else {
                    scanError = "Error al procesar respuesta"
                }
            }
        }.resume()
    }
}

// Sheet para seleccionar categoría
struct CategoriaPickerSheet: View {
    @Binding var selectedCategoria: String
    let categorias: [(emoji: String, nombre: String)]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Título
            HStack {
                Text("Seleccionar categoría")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)

            // Grid de categorías
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(categorias, id: \.nombre) { cat in
                        Button(action: {
                            selectedCategoria = cat.nombre
                            onDismiss()
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selectedCategoria == cat.nombre ? ualaBlue : Color.gray.opacity(0.1))
                                        .frame(width: 56, height: 56)
                                    Text(cat.emoji)
                                        .font(.system(size: 28))
                                }

                                Text(cat.nombre)
                                    .font(.system(size: 13, weight: selectedCategoria == cat.nombre ? .semibold : .regular))
                                    .foregroundColor(selectedCategoria == cat.nombre ? ualaBlue : .primary)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color.white)
    }
}

struct ConfirmationRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
    }
}

// MARK: - Generic Success View (Reutilizable)
struct GenericSuccessView: View {
    let amount: String
    let title: String
    let subtitle: String
    let recipientLabel: String
    let recipientName: String
    let buttonText: String
    let onDone: () -> Void

    var accentColor: Color = ualaBlue
    var showConfettiAnimation: Bool = true

    @State private var showCheck = false
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var celebrationScale: CGFloat = 0
    @State private var emojiOffset: CGFloat = 50
    @State private var pulseCheck = false

    var body: some View {
        ZStack {
            // Fondo
            Color.white.ignoresSafeArea()

            // Confetti
            if showConfetti && showConfettiAnimation {
                TransferConfettiView()
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    // Emoji de celebración
                    Text("🎉")
                        .font(.system(size: 40))
                        .offset(y: emojiOffset)
                        .opacity(showContent ? 1 : 0)

                    // Checkmark animado con pulso (verde)
                    ZStack {
                        // Círculos de onda
                        Circle()
                            .stroke(Color.green.opacity(0.2), lineWidth: 2)
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseCheck ? 1.3 : 0.8)
                            .opacity(pulseCheck ? 0 : 0.5)

                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseCheck ? 1.2 : 0.9)
                            .opacity(pulseCheck ? 0 : 0.6)

                        // Círculo principal
                        Circle()
                            .fill(Color.green)
                            .frame(width: 100, height: 100)
                            .scaleEffect(showCheck ? 1 : 0)

                        // Checkmark
                        Image(systemName: "checkmark")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showCheck ? 1 : 0)
                    }

                    // Texto de éxito
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 32, weight: .bold))

                        Text(subtitle)
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)

                    // Monto y destinatario en card
                    VStack(spacing: 12) {
                        FormattedAmountView(amount: amount, fontSize: 44, color: accentColor)

                        HStack(spacing: 8) {
                            Text(recipientLabel)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            Text(recipientName)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(accentColor.opacity(0.05))
                    )
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(celebrationScale)
                }

                Spacer()

                // Botón
                Button(action: onDone) {
                    Text(buttonText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(accentColor)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            // Confetti inmediato
            showConfetti = true

            // Haptic success
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // Checkmark con bounce
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1)) {
                showCheck = true
            }

            // Pulso del check
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.5)) {
                pulseCheck = true
            }

            // Contenido
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showContent = true
                emojiOffset = 0
            }

            // Card con celebración
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
                celebrationScale = 1.0
            }

            // Haptic adicional para la fiesta
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

// MARK: - Transfer Success View (wrapper para compatibilidad)
struct TransferSuccessView: View {
    let aliasData: AliasData
    let amount: String
    let onDone: () -> Void

    var body: some View {
        GenericSuccessView(
            amount: amount,
            title: "¡Listo! 🙌",
            subtitle: "Tu transferencia fue enviada",
            recipientLabel: "para",
            recipientName: aliasData.nombreCompleto,
            buttonText: "¡Genial!",
            onDone: onDone
        )
    }
}

// Confetti para la pantalla de éxito de transferencia
struct TransferConfettiView: View {
    let colors: [Color] = [
        Color(red: 0.29, green: 0.23, blue: 1.0),      // Azul Ualá
        Color(red: 0.4, green: 0.35, blue: 1.0),       // Azul claro
        Color(red: 0.55, green: 0.5, blue: 1.0),       // Lavanda
        Color.yellow,
        Color.green,
        Color.pink,
        Color.orange,
        Color.white
    ]

    @State private var particles: [(id: Int, color: Color, x: CGFloat, delay: Double, size: CGFloat, shape: Int)] = []
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    TransferConfettiParticle(
                        color: particle.color,
                        startX: particle.x,
                        delay: particle.delay,
                        screenHeight: geo.size.height,
                        particleSize: particle.size,
                        shape: particle.shape,
                        animate: animate
                    )
                }
            }
            .onAppear {
                // Generar partículas
                for i in 0..<80 {
                    particles.append((
                        id: i,
                        color: colors.randomElement()!,
                        x: CGFloat.random(in: 0...geo.size.width),
                        delay: Double.random(in: 0...0.8),
                        size: CGFloat.random(in: 8...16),
                        shape: Int.random(in: 0...2) // 0: rect, 1: circle, 2: star
                    ))
                }
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}

struct TransferConfettiParticle: View {
    let color: Color
    let startX: CGFloat
    let delay: Double
    let screenHeight: CGFloat
    let particleSize: CGFloat
    let shape: Int
    let animate: Bool

    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    @State private var scale: Double = 1

    var body: some View {
        Group {
            switch shape {
            case 0:
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: particleSize, height: particleSize * 0.6)
            case 1:
                Circle()
                    .fill(color)
                    .frame(width: particleSize * 0.7, height: particleSize * 0.7)
            default:
                // Estrella simplificada
                Image(systemName: "star.fill")
                    .font(.system(size: particleSize * 0.8))
                    .foregroundColor(color)
            }
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .rotation3DEffect(.degrees(rotation * 2), axis: (x: 1, y: 0, z: 0))
        .opacity(opacity)
        .position(position)
        .onAppear {
            position = CGPoint(x: startX, y: -30)
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
        withAnimation(.easeOut(duration: 3.0).delay(delay)) {
            position = CGPoint(
                x: startX + CGFloat.random(in: -100...100),
                y: screenHeight + 100
            )
            rotation = Double.random(in: 720...1440)
            opacity = 0
            scale = 0.3
        }
    }
}
