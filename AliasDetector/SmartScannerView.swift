import SwiftUI
import UIKit
import AVFoundation

// MARK: - Smart Scanner View
struct SmartScannerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isAnalyzing = false
    @State private var detectedType: DetectedType?
    @State private var detectedAlias: String?
    @State private var validatedAliasData: AliasData?
    @State private var statusMessage = "Escaneá un alias o QR"
    @State private var showResult = false

    enum DetectedType {
        case alias(String)
        case qr
        case none
    }

    var body: some View {
        ZStack {
            // Camera with back button built-in
            SmartCameraView(
                onCapture: { image in
                    if !isAnalyzing {
                        analyzeImage(image)
                    }
                },
                onDismiss: {
                    dismiss()
                }
            )
            .ignoresSafeArea()

            // Status pill overlay
            VStack {
                Spacer()

                HStack(spacing: 8) {
                    if isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "viewfinder")
                            .foregroundColor(.white)
                    }
                    Text(statusMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.6))
                .cornerRadius(24)
                .padding(.bottom, 100)
            }
        }
        .fullScreenCover(isPresented: $showResult) {
            resultDestination
        }
    }

    @ViewBuilder
    private var resultDestination: some View {
        if let type = detectedType {
            switch type {
            case .alias:
                // Go directly to transfer flow with validated alias
                if let aliasData = validatedAliasData {
                    TransferFlowView(
                        aliasData: aliasData,
                        onCancel: { dismiss() },
                        onComplete: { dismiss() }
                    )
                } else {
                    EmptyView()
                }
            case .qr:
                QRPlaceholderView()
            case .none:
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }

    private func analyzeImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        isAnalyzing = true
        statusMessage = "Analizando imagen..."

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
        append("Sos un experto en clasificar imágenes. Respondé MUY breve con una sola palabra.\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"user_prompt\"\r\n\r\n")
        append("Analizá esta imagen y clasificá qué contiene. Respondé SOLO una de estas palabras:\n- QR: si ves un código QR (cuadrado con patrón de puntos/módulos blancos y negros)\n- ALIAS: si ves texto que parece un alias bancario CBU/CVU (formato: palabras separadas por puntos, ej: sol.verde.rio, belen.suarez)\n- NINGUNO: si no detectás ninguno de los anteriores\n\nRespondé SOLO: QR, ALIAS o NINGUNO\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"files\"; filename=\"scan.jpg\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        append("\r\n--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    isAnalyzing = false
                    statusMessage = "Error de conexión. Intentá de nuevo."
                    return
                }

                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let resp = json["response"] as? String else {
                    isAnalyzing = false
                    statusMessage = "Error al analizar. Intentá de nuevo."
                    return
                }

                let classification = resp.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

                if classification.contains("QR") {
                    detectedType = .qr
                    statusMessage = "¡QR detectado!"
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showResult = true
                    }
                } else if classification.contains("ALIAS") {
                    // Use existing alias detection logic
                    detectAlias(from: image)
                } else {
                    isAnalyzing = false
                    statusMessage = "No detecté nada. Intentá de nuevo."
                }
            }
        }.resume()
    }

    private func detectAlias(from image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        statusMessage = "Buscando alias..."

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
        append("Sos un experto en identificar alias CBU/CVU argentinos en imágenes. Respondé MUY breve.\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"user_prompt\"\r\n\r\n")
        append("Buscá en la imagen un alias CBU/CVU argentino. Reglas del alias: entre 6 y 20 caracteres, solo letras (a-z), números (0-9) y punto (.) como separador. NO tiene guiones, espacios, acentos ni ñ. Formato común: tres palabras separadas por puntos (ej: sol.verde.rio, casa.luna.mar). Respondé SOLO el alias encontrado. Si no hay alias: NO_ALIAS\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"files\"; filename=\"alias.jpg\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        append("\r\n--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isAnalyzing = false

                if error != nil {
                    statusMessage = "Error de conexión"
                    return
                }

                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let resp = json["response"] as? String else {
                    statusMessage = "Error al buscar alias"
                    return
                }

                let result = resp.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                if result.contains("no_alias") || result.contains("no encontr") {
                    isAnalyzing = false
                    statusMessage = "No encontré un alias. Intentá de nuevo."
                } else {
                    let alias = extractAlias(from: result)
                    if alias.count >= 6 && alias.count <= 20 {
                        statusMessage = "Validando \(alias)..."
                        validateAlias(alias)
                    } else {
                        isAnalyzing = false
                        statusMessage = "No encontré un alias válido"
                    }
                }
            }
        }.resume()
    }

    private func validateAlias(_ alias: String) {
        let urlString = "\(Config.localAPIUrl)/validate/\(alias.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? alias)"
        guard let url = URL(string: urlString) else {
            isAnalyzing = false
            statusMessage = "Error al validar alias"
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isAnalyzing = false

                guard error == nil,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let valid = json["valid"] as? Bool else {
                    statusMessage = "Error al validar. Intentá de nuevo."
                    return
                }

                if valid, let dataDict = json["data"] as? [String: Any] {
                    validatedAliasData = AliasData(
                        alias: dataDict["alias"] as? String ?? alias,
                        tipo: dataDict["tipo"] as? String ?? "?",
                        entidad: dataDict["entidad"] as? String ?? "?",
                        nombreCompleto: dataDict["nombre_completo"] as? String ?? "?",
                        cuitCuil: dataDict["cuit_cuil"] as? String ?? "?"
                    )
                    detectedType = .alias(alias)
                    statusMessage = "¡Alias verificado!"
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showResult = true
                    }
                } else {
                    statusMessage = "Alias no registrado: \(alias)"
                }
            }
        }.resume()
    }

    private func extractAlias(from text: String) -> String {
        let pattern = #"[a-z][a-z0-9]*(\.[a-z0-9]+)+"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let alias = String(text[range]).lowercased()
            if alias.count >= 6 && alias.count <= 20 {
                return alias
            }
        }
        let cleaned = text
            .lowercased()
            .components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.").inverted)
            .joined()
        return cleaned
    }
}

// MARK: - Smart Camera View
struct SmartCameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> SmartCameraController {
        let controller = SmartCameraController()
        controller.onCapture = onCapture
        controller.onDismiss = onDismiss
        return controller
    }

    func updateUIViewController(_ uiViewController: SmartCameraController, context: Context) {}
}

class SmartCameraController: UIViewController {
    var onCapture: ((UIImage) -> Void)?
    var onDismiss: (() -> Void)?
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastCaptureTime: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }

        photoOutput = AVCapturePhotoOutput()

        if captureSession?.canAddInput(input) == true {
            captureSession?.addInput(input)
        }
        if let output = photoOutput, captureSession?.canAddOutput(output) == true {
            captureSession?.addOutput(output)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.addSublayer(previewLayer!)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }

        // Add back button
        let backButton = UIButton(frame: CGRect(x: 20, y: 60, width: 44, height: 44))
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backButton.layer.cornerRadius = 22
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let backImage = UIImage(systemName: "arrow.left", withConfiguration: config)
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        view.addSubview(backButton)

        // Add capture button
        let captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        captureButton.center = CGPoint(x: view.center.x, y: view.bounds.height - 140)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 40
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        // Inner circle
        let innerCircle = UIView(frame: CGRect(x: 8, y: 8, width: 64, height: 64))
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 32
        innerCircle.isUserInteractionEnabled = false
        captureButton.addSubview(innerCircle)
    }

    @objc private func dismissTapped() {
        onDismiss?()
    }

    @objc private func capturePhoto() {
        // Prevent rapid captures
        if let lastTime = lastCaptureTime, Date().timeIntervalSince(lastTime) < 2 {
            return
        }
        lastCaptureTime = Date()

        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
}

extension SmartCameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        DispatchQueue.main.async {
            self.onCapture?(image)
        }
    }
}

// MARK: - QR Placeholder View
struct QRPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "qrcode")
                    .font(.system(size: 80))
                    .foregroundColor(ualaBlue)

                Text("QR")
                    .font(.system(size: 32, weight: .bold))

                Text("Funcionalidad de QR próximamente")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                Button(action: { dismiss() }) {
                    Text("Volver")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(ualaBlue)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Barcode Placeholder View
struct BarcodePlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "barcode")
                    .font(.system(size: 80))
                    .foregroundColor(ualaBlue)

                Text("Pagar Servicio")
                    .font(.system(size: 32, weight: .bold))

                Text("Funcionalidad próximamente")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                Button(action: { dismiss() }) {
                    Text("Volver")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(ualaBlue)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Servicio Placeholder View
struct ServicioPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ualaBlue)

                Text("Servicio")
                    .font(.system(size: 32, weight: .bold))

                Text("Pago de servicios próximamente")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                Button(action: { dismiss() }) {
                    Text("Volver")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(ualaBlue)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
        }
    }
}

#Preview {
    SmartScannerView()
}
