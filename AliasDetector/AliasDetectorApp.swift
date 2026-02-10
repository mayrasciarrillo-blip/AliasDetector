import SwiftUI

@main
struct AliasDetectorApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Refrescar token cada vez que la app vuelve a primer plano
                Task {
                    let success = await Config.refreshToken()
                    if success {
                        print("✅ Token actualizado (app activa)")
                    } else {
                        print("⚠️ No se pudo actualizar el token")
                    }
                }
            }
        }
    }
}
