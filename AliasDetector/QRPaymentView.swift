import SwiftUI
import UIKit

// MARK: - Payment Method Model
struct PaymentMethod: Identifiable {
    let id = UUID()
    let type: String
    let balance: Double
    let lastDigits: String?
    let cardColor: LinearGradient
    let icon: String?
}

// MARK: - Tipo de pago
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

// MARK: - Payment View (genérico para QR y Barcode)
struct PaymentView: View {
    @Environment(\.dismiss) private var dismiss
    var paymentType: PaymentType = .qr
    var onGoHome: (() -> Void)? = nil

    // Datos del pago según tipo
    var amount: Double {
        paymentType == .qr ? 11000.00 : 155000.00
    }
    var recipient: String {
        paymentType == .qr ? "Crujen Milanesas" : "Edenor"
    }

    // Métodos de pago disponibles
    let paymentMethods: [PaymentMethod] = [
        PaymentMethod(
            type: "TARJETA PREPAGA",
            balance: 35000.00,
            lastDigits: "5678",
            cardColor: LinearGradient(
                colors: [Color(red: 0.85, green: 0.4, blue: 0.5), Color(red: 0.7, green: 0.3, blue: 0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            icon: "mastercard"
        ),
        PaymentMethod(
            type: "CAJA DE AHORRO EN PESOS",
            balance: 35000.00,
            lastDigits: nil,
            cardColor: LinearGradient(
                colors: [Color(red: 0.25, green: 0.25, blue: 0.3), Color(red: 0.15, green: 0.15, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            icon: nil
        )
    ]

    @State private var selectedMethodIndex = 0
    @State private var showPaymentSuccess = false
    @State private var isProcessing = false
    @State private var isFlipping = false
    @State private var flipRotation: Double = 0

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header fijo arriba
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isProcessing ? .clear : .primary)
                    }
                    .disabled(isProcessing)

                    Spacer()

                    Text(paymentType.title)
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    Color.clear.frame(width: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Contenido central que se adapta
                VStack(spacing: 0) {
                    Spacer()

                    // Amount section
                    VStack(spacing: 12) {
                        Text("Vas a pagar")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        FormattedAmountView(amount: String(amount), fontSize: 56)

                        Text("a \(recipient)")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Payment method section - container fijo
                    VStack(spacing: 16) {
                        HStack {
                            Text("Con este método de pago:")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(action: {
                                flipCard()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 12))
                                    Text("Cambiar")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(ualaBlue)
                            }
                            .disabled(isFlipping)
                        }
                        .padding(.horizontal, 20)

                        // Card container con altura fija para evitar movimiento
                        ZStack {
                            LiquidGlassCardView(method: paymentMethods[selectedMethodIndex])
                                .rotation3DEffect(
                                    .degrees(flipRotation),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.3
                                )
                        }
                        .frame(height: 100)
                        .padding(.horizontal, 20)
                    }

                    Spacer()
                }
                .frame(height: geo.size.height - 160)

                // Botón fijo abajo
                Button(action: {
                    processPayment()
                }) {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isProcessing ? "Procesando..." : "Pagar")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isProcessing ? Color.gray : ualaBlue)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showPaymentSuccess) {
            PaymentSuccessView(amount: amount, recipient: recipient, paymentType: paymentType) {
                showPaymentSuccess = false
                dismiss()
                onGoHome?()  // Volver a home
            }
        }
    }

    private func processPayment() {
        isProcessing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isProcessing = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showPaymentSuccess = true
        }
    }

    private func flipCard() {
        guard !isFlipping else { return }
        isFlipping = true

        // Haptic feedback al inicio
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Primera mitad del flip (0 a 90 grados)
        withAnimation(.easeIn(duration: 0.15)) {
            flipRotation = 90
        }

        // Cambiar la tarjeta cuando está de canto (invisible)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            selectedMethodIndex = (selectedMethodIndex + 1) % paymentMethods.count

            // Segunda mitad del flip (90 a 0 grados, viene desde atrás)
            flipRotation = -90
            withAnimation(.easeOut(duration: 0.15)) {
                flipRotation = 0
            }

            // Haptic feedback al completar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                isFlipping = false
            }
        }
    }
}

// MARK: - Liquid Glass Card View
struct LiquidGlassCardView: View {
    let method: PaymentMethod

    var body: some View {
        ZStack {
            // Fondo con gradiente y blur
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: method.icon == "mastercard"
                            ? [Color(red: 0.9, green: 0.3, blue: 0.4).opacity(0.8),
                               Color(red: 0.7, green: 0.2, blue: 0.35).opacity(0.9)]
                            : [Color(red: 0.2, green: 0.2, blue: 0.25).opacity(0.85),
                               Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Capa de brillo superior (glass effect)
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )

            // Reflejo inferior sutil
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 50)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Borde con gradiente brillante
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // Contenido
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(method.type)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .tracking(0.5)

                    FormattedAmountView(amount: String(method.balance), fontSize: 20, color: .white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    if method.icon == "mastercard" {
                        // Mastercard logo con glow
                        ZStack {
                            HStack(spacing: -10) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 28, height: 28)
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 28, height: 28)
                            }
                            .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 2)
                        }
                    } else {
                        // Ualá logo en blanco para otras tarjetas
                        Image("UalaLogo")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 0)
                    }

                    if let digits = method.lastDigits {
                        Text("•••• \(digits)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        .shadow(color: method.icon == "mastercard"
                ? Color(red: 0.9, green: 0.3, blue: 0.4).opacity(0.3)
                : Color.black.opacity(0.15),
                radius: 20, x: 0, y: 10)
    }
}

// MARK: - Payment Success View (usa GenericSuccessView)
struct PaymentSuccessView: View {
    let amount: Double
    let recipient: String
    let paymentType: PaymentType
    let onDone: () -> Void

    var body: some View {
        GenericSuccessView(
            amount: String(amount),
            title: "¡Listo! 🙌",
            subtitle: "Tu pago fue realizado",
            recipientLabel: "a",
            recipientName: recipient,
            buttonText: "¡Genial!",
            onDone: onDone
        )
    }
}

#Preview {
    PaymentView(paymentType: .qr)
}
