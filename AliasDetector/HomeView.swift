import SwiftUI
import UIKit

// MARK: - Home View
struct HomeView: View {
    @State private var showTransferScanner = false
    @State private var selectedTab = 0
    @State private var hideBalance = false

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Blue gradient header section
                        ZStack {
                            // Gradient background
                            LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.20, blue: 0.95),
                                    Color(red: 0.35, green: 0.30, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            VStack(spacing: 20) {
                                // Header
                                HomeHeader()

                                // Balance section
                                BalanceSection(hideBalance: $hideBalance)

                                // Quick actions
                                QuickActionsRow(onTransferTap: {
                                    showTransferScanner = true
                                })
                            }
                            .padding(.top, 60)
                            .padding(.bottom, 24)
                        }

                        // White/gray background sections
                        VStack(spacing: 16) {
                            // Services row
                            ServicesRow()
                                .padding(.top, 16)

                            // Dollar rates
                            DollarRatesSection()

                            // Tasa Plus card
                            TasaPlusCard()

                            // Credit card
                            CreditCardSection()

                            // Promotional cards
                            PromoCardsSection()

                            // Promociones
                            PromocionesSection()

                            // Movimientos
                            MovimientosSection()

                            // Bottom spacing for tab bar
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                }

                Spacer()
            }

            // Floating Tab Bar
            VStack {
                Spacer()
                HomeTabBar(selectedTab: $selectedTab, onTransferTap: {
                    showTransferScanner = true
                }, onSmartScanTap: {
                    showTransferScanner = true
                })
            }
        }
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(isPresented: $showTransferScanner) {
            ContentView()
        }
    }
}

// MARK: - Header
struct HomeHeader: View {
    var body: some View {
        HStack {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text("M")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Hola, Mayra")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // Notification bell
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 16)

            // Help button
            Button(action: {}) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    Text("?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Balance Section
struct BalanceSection: View {
    @Binding var hideBalance: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Account selector
            HStack(spacing: 8) {
                Text("Caja de Ahorro en")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))

                // Currency pill
                HStack(spacing: 6) {
                    Text("🇦🇷")
                        .font(.system(size: 12))
                    Text("ARS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.2))
                .cornerRadius(14)

                Text("🇺🇸")
                    .font(.system(size: 16))
            }

            // Balance amount
            HStack(spacing: 4) {
                if hideBalance {
                    Text("$ ••••••")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("$")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    Text("20.501")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    Text(",73")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: -10)
                }

                Button(action: { hideBalance.toggle() }) {
                    Image(systemName: hideBalance ? "eye.slash" : "eye")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.leading, 8)
            }

            // Growth indicator
            Button(action: {}) {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 14))
                    Text("26%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Tu plata está creciendo")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
            }
        }
    }
}

// MARK: - Quick Actions Row
struct QuickActionsRow: View {
    let onTransferTap: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            QuickActionButton(icon: "plus", label: "Ingresar", action: {})
            QuickActionButton(icon: "arrow.right", label: "Transferir", action: onTransferTap)
            QuickActionButton(icon: "arrow.up.right", label: "Retirar", action: {})
            QuickActionButton(icon: "creditcard", label: "Tu cuenta", action: {})
        }
        .padding(.horizontal, 20)
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.15, blue: 0.8))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Services Row
struct ServicesRow: View {
    let services = [
        ("heart.fill", "Seguro\nde Vida", true),
        ("building.columns", "Dólar Oficial", false),
        ("storefront", "Tu Negocio", false),
        ("banknote", "Préstamos", false),
        ("iphone", "Recargas", false)
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(services, id: \.1) { service in
                    ServiceCard(icon: service.0, label: service.1, isNew: service.2)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct ServiceCard: View {
    let icon: String
    let label: String
    let isNew: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(ualaBlue)
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 70)
                }
                .frame(width: 85, height: 85)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                if isNew {
                    Text("Nuevo")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .cornerRadius(4)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: -4, y: -4)
                }
            }
        }
    }
}

// MARK: - Dollar Rates Section
struct DollarRatesSection: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                DollarRateCard(type: "Dólar Oficial", rate: "1.464,00")
                DollarRateCard(type: "Dólar MEP", rate: "1.465,67")
            }
            .padding(.horizontal, 4)
        }
    }
}

struct DollarRateCard: View {
    let type: String
    let rate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(type)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Text("Cotización final")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            HStack {
                Text("COMPRA")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(12)
            }

            Text("$ \(rate)")
                .font(.system(size: 22, weight: .bold))
        }
        .padding(16)
        .frame(width: 170)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Tasa Plus Card
struct TasaPlusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("¡Mantené tu Tasa Plus el mes que viene!")
                    .font(.system(size: 15, weight: .semibold))
                Text("🔥")
            }

            Text("Más usás Ualá, más sube tu tasa.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            // Progress bar
            HStack(spacing: 0) {
                // 20% segment (active)
                Rectangle()
                    .fill(Color.green)
                    .frame(height: 4)

                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)

                // 23% segment
                Rectangle()
                    .fill(Color(UIColor.systemGray4))
                    .frame(height: 4)

                Circle()
                    .stroke(Color(UIColor.systemGray4), lineWidth: 2)
                    .frame(width: 12, height: 12)

                // 26% segment
                Rectangle()
                    .fill(Color(UIColor.systemGray4))
                    .frame(height: 4)

                Circle()
                    .stroke(Color(UIColor.systemGray4), lineWidth: 2)
                    .frame(width: 12, height: 12)
            }
            .padding(.vertical, 8)

            HStack {
                Text("20%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
                Spacer()
                Text("23%")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Text("26%")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Text("Te faltan $ 239.250 para subir tu tasa a 23%.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Credit Card Section
struct CreditCardSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Card
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        Color(red: 0.25, green: 0.20, blue: 0.85),
                        Color(red: 0.35, green: 0.30, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 0) {
                    // Mastercard logo
                    HStack(spacing: -8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 24, height: 24)
                    }
                    .padding(.bottom, 40)

                    Text("Tarjeta de Crédito")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    HStack {
                        Text("•••• 4763")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(20)
            }
            .frame(height: 160)

            // Due date
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("Tu fecha de vencimiento es el 09/02.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Promo Cards Section
struct PromoCardsSection: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                PromoCard(
                    icon: "heart.circle.fill",
                    iconColor: .pink,
                    title: "Nuevo seguro de vida",
                    subtitle: "Desde $4.900 fijos por mes. Cuidá a quienes más amás."
                )

                PromoCard(
                    icon: "giftcard.fill",
                    iconColor: .orange,
                    title: "Regalá Ualá",
                    subtitle: "Enviá dinero a tus seres queridos fácilmente."
                )
            }
            .padding(.horizontal, 4)
        }
    }
}

struct PromoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(width: 280, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Promociones Section
struct PromocionesSection: View {
    let promos = [
        "Lucciano's",
        "Patagonia",
        "Atalaya"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Promociones")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(promos, id: \.self) { promo in
                        PromocionCard(brand: promo)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct PromocionCard: View {
    let brand: String

    var body: some View {
        VStack(spacing: 12) {
            // Brand logo placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemGray6))
                .frame(width: 100, height: 50)
                .overlay(
                    Text(brand)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                )

            Text("Descuento")
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(8)

            Text("Hasta 35%")
                .font(.system(size: 14, weight: .bold))

            Text("Todos los días")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 130)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Movimientos Section
struct MovimientosSection: View {
    let movimientos = [
        ("Rendimientos", "Operación exitosa", "+ $ 14,67", "04/02"),
        ("Reintegro bares y restaurants", "Promoción Ualá", "+ $ 7.525,00", "03/02")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Movimientos")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(movimientos, id: \.0) { mov in
                    MovimientoRow(
                        title: mov.0,
                        subtitle: mov.1,
                        amount: mov.2,
                        date: mov.3
                    )
                    if mov.0 != movimientos.last?.0 {
                        Divider()
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct MovimientoRow: View {
    let title: String
    let subtitle: String
    let amount: String
    let date: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
                Image(systemName: "plus")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }
}

// MARK: - Tab Bar (Liquid Glass Style)
struct HomeTabBar: View {
    @Binding var selectedTab: Int
    let onTransferTap: () -> Void
    let onSmartScanTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill", label: "Inicio", isSelected: selectedTab == 0) {
                selectedTab = 0
            }

            TabBarItem(icon: "arrow.right", label: "Transferir", isSelected: selectedTab == 1) {
                onTransferTap()
            }

            // Center button - QR Scanner
            Button(action: { onSmartScanTap() }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 26))
                        .foregroundColor(Color(UIColor.darkGray))
                }
            }
            .offset(y: -6)

            TabBarItem(icon: "doc.text.fill", label: "Servicios", isSelected: selectedTab == 3) {
                selectedTab = 3
            }

            TabBarItem(icon: "square.grid.2x2.fill", label: "Más", isSelected: selectedTab == 4) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Fondo gris azulado con glass effect
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(red: 0.85, green: 0.87, blue: 0.92).opacity(0.95))

                // Borde sutil
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            }
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(Color(UIColor.darkGray))
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HomeView()
}
