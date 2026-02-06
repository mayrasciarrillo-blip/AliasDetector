import SwiftUI
import AVFoundation
import Vision
import CoreMotion

// Código detectado con su posición
struct DetectedCode: Identifiable {
    let id = UUID()
    let type: CodeType
    let payload: String
    let boundingBox: CGRect  // Coordenadas normalizadas (0-1)

    enum CodeType {
        case qr
        case barcode
    }

    var displayName: String {
        switch type {
        case .qr: return "QR"
        case .barcode: return "Código de barras"
        }
    }
}

// Resultado del escaneo
enum ScanResult {
    case qrCode(String)
    case barcode(String)
    case multipleCodes([DetectedCode])  // Múltiples códigos detectados
    case needsOCR(UIImage)  // Cuando no hay QR/barcode, enviar a Gemini para alias
    case nothing
}

struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    var onScanResult: (ScanResult) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraPreviewViewDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func didDetectResult(_ result: ScanResult, image: UIImage?) {
            DispatchQueue.main.async {
                if let image = image {
                    self.parent.capturedImage = image
                }
                self.parent.onScanResult(result)
            }
        }
    }
}

// Legacy compatibility
extension CameraView {
    init(capturedImage: Binding<UIImage?>, onFrameCaptured: @escaping (UIImage) -> Void) {
        self._capturedImage = capturedImage
        self.onScanResult = { result in
            if case .needsOCR(let image) = result {
                onFrameCaptured(image)
            }
        }
    }
}

protocol CameraPreviewViewDelegate: AnyObject {
    func didDetectResult(_ result: ScanResult, image: UIImage?)
}

class CameraPreviewView: UIView {
    weak var delegate: CameraPreviewViewDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let outputQueue = DispatchQueue(label: "camera.output.queue")

    private var lastCaptureTime: Date = .distantPast
    private let visionInterval: TimeInterval = 0.15  // Vision es rápido, escanear frecuentemente
    private let ocrInterval: TimeInterval = 1.5      // OCR (Gemini) más lento
    private var lastOCRTime: Date = .distantPast
    private var currentOrientation: UIDeviceOrientation = .portrait
    private var startTime: Date = Date()
    private let initialDelay: TimeInterval = 0.5     // Reducido para respuesta más rápida

    // Debouncing - evitar re-detectar el mismo código
    private var lastDetectedCode: String?
    private var lastDetectionTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 3.0  // No re-detectar el mismo código por 3 segundos

    // Acumulación de códigos para detección múltiple
    private var accumulatedCodes: [String: DetectedCode] = [:]  // key = payload para evitar duplicados
    private var accumulationStartTime: Date?
    private let accumulationWindow: TimeInterval = 0.5  // Esperar 0.5s para acumular códigos

    // Vision requests (reutilizables)
    private lazy var barcodeRequest: VNDetectBarcodesRequest = {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr, .ean13, .ean8, .code128, .code39, .upce, .codabar, .itf14, .i2of5, .pdf417, .aztec, .dataMatrix]
        return request
    }()

    // Motion detection - evitar OCR cuando la cámara se mueve
    private let motionManager = CMMotionManager()
    private var isDeviceStable = true  // Asumir estable inicialmente
    private let stabilityThreshold: Double = 0.4   // Mide cambio entre frames
    private var lastAcceleration: (x: Double, y: Double, z: Double)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
        setupOrientationObserver()
        setupMotionDetection()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
        setupMotionDetection()
        setupOrientationObserver()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    private func setupOrientationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }

    @objc private func orientationChanged() {
        currentOrientation = UIDevice.current.orientation
    }

    private func setupCamera() {
        // Verificar permisos de cámara primero
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.configureCamera()
                    }
                }
            }
        case .denied, .restricted:
            print("Camera access denied or restricted")
        @unknown default:
            break
        }
    }

    private func configureCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let captureSession = captureSession,
              let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not get camera device")
            return
        }

        do {
            // Configurar autofoco
            try camera.lockForConfiguration()
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            camera.unlockForConfiguration()

            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            // Video output
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput?.setSampleBufferDelegate(self, queue: outputQueue)
            videoOutput?.alwaysDiscardsLateVideoFrames = true

            if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            // Preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill

            if let previewLayer = previewLayer {
                layer.addSublayer(previewLayer)
            }

            // Forzar layout para actualizar el frame del preview layer
            setNeedsLayout()
            layoutIfNeeded()

            // Start session
            sessionQueue.async {
                captureSession.startRunning()
            }

        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    private func setupMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.1  // 100ms
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }

            // Medir CAMBIO respecto al frame anterior (no posición absoluta)
            // Así funciona en cualquier orientación del teléfono
            if let last = self.lastAcceleration {
                let deltaX = abs(data.acceleration.x - last.x)
                let deltaY = abs(data.acceleration.y - last.y)
                let deltaZ = abs(data.acceleration.z - last.z)
                let movement = deltaX + deltaY + deltaZ

                self.isDeviceStable = movement < self.stabilityThreshold
            }

            self.lastAcceleration = (data.acceleration.x, data.acceleration.y, data.acceleration.z)
        }
    }

    private var isStableEnoughForOCR: Bool {
        return isDeviceStable
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    // Resetear debounce para permitir re-detectar el mismo código
    func resetDebounce() {
        lastDetectedCode = nil
        lastDetectionTime = .distantPast
    }
}

extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()

        // Esperar delay inicial para que la cámara estabilice
        guard now.timeIntervalSince(startTime) >= initialDelay else {
            return
        }

        // Rate limiting para Vision (muy frecuente porque es local y rápido)
        guard now.timeIntervalSince(lastCaptureTime) >= visionInterval else {
            return
        }
        lastCaptureTime = now

        // Configurar orientación del video para que coincida con el preview
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Usar Vision para detectar QR y códigos de barras (INSTANTÁNEO)
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        do {
            try handler.perform([barcodeRequest])

            if let results = barcodeRequest.results, !results.isEmpty {
                // Iniciar ventana de acumulación si no está activa
                if accumulationStartTime == nil {
                    accumulationStartTime = now
                }

                // Acumular códigos detectados en este frame
                for result in results {
                    guard let payload = result.payloadStringValue, !payload.isEmpty else { continue }

                    let codeType: DetectedCode.CodeType = result.symbology == .qr ? .qr : .barcode
                    let boundingBox = result.boundingBox

                    let code = DetectedCode(
                        type: codeType,
                        payload: payload,
                        boundingBox: boundingBox
                    )
                    // Usar payload como key para evitar duplicados
                    accumulatedCodes[payload] = code
                }

                // Verificar si pasó la ventana de acumulación
                if let startTime = accumulationStartTime,
                   now.timeIntervalSince(startTime) >= accumulationWindow {
                    // Ventana cerrada: decidir qué hacer con los códigos acumulados
                    let allCodes = Array(accumulatedCodes.values)

                    // Limpiar acumulación
                    accumulatedCodes.removeAll()
                    accumulationStartTime = nil

                    if allCodes.count == 1 {
                        // Solo un código: procesar directamente
                        let code = allCodes[0]
                        if code.type == .qr {
                            delegate?.didDetectResult(.qrCode(code.payload), image: nil)
                        } else {
                            let codeKey = "barcode:\(code.payload)"
                            if codeKey == lastDetectedCode && now.timeIntervalSince(lastDetectionTime) < debounceInterval {
                                return
                            }
                            lastDetectedCode = codeKey
                            lastDetectionTime = now
                            delegate?.didDetectResult(.barcode(code.payload), image: nil)
                        }
                        return
                    } else if allCodes.count > 1 {
                        // Múltiples códigos: enviar todos para que el usuario elija
                        delegate?.didDetectResult(.multipleCodes(allCodes), image: nil)
                        return
                    }
                }
                return  // Seguir acumulando, no pasar a OCR
            } else {
                // No se detectaron códigos: resetear acumulación
                if !accumulatedCodes.isEmpty {
                    accumulatedCodes.removeAll()
                    accumulationStartTime = nil
                }
            }
        } catch {
            // Vision falló, continuar con OCR
        }

        // No se detectó QR ni barcode con Vision
        // Enviar a Gemini para OCR de alias (con rate limiting más lento)
        guard now.timeIntervalSince(lastOCRTime) >= ocrInterval else {
            return
        }

        // Solo enviar a OCR si el dispositivo está estable (no se está moviendo)
        guard isStableEnoughForOCR else {
            return
        }

        lastOCRTime = now

        // Usar imagen recortada del centro para OCR más rápido (menos datos a enviar)
        guard let croppedImage = croppedCenterImage(from: sampleBuffer) else {
            return
        }

        delegate?.didDetectResult(.needsOCR(croppedImage), image: croppedImage)
    }

    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        // Dimensiones del buffer (viene en landscape del sensor)
        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)

        // Aspect ratio de la pantalla en portrait
        let screenBounds = UIScreen.main.bounds
        let screenAspect = screenBounds.width / screenBounds.height  // ancho/alto en portrait

        // El buffer viene landscape, así que su aspect ratio es bufferWidth/bufferHeight
        // Pero después de rotar será bufferHeight/bufferWidth (que es el ancho final / alto final)
        // Necesitamos recortar el buffer ANTES de rotar para que coincida

        // Después de rotar 90°: ancho_final = bufferHeight, alto_final = bufferWidth
        // Queremos: ancho_final / alto_final = screenAspect
        // Entonces: bufferHeight / bufferWidth = screenAspect
        // Si no coincide, recortamos

        let targetWidth: Int
        let targetHeight: Int

        let currentAspectAfterRotation = CGFloat(bufferHeight) / CGFloat(bufferWidth)

        if currentAspectAfterRotation > screenAspect {
            // Después de rotar será muy ancho, recortar altura del buffer (que será el ancho final)
            targetHeight = Int(CGFloat(bufferWidth) * screenAspect)
            targetWidth = bufferWidth
        } else {
            // Después de rotar será muy alto, recortar ancho del buffer (que será el alto final)
            targetWidth = Int(CGFloat(bufferHeight) / screenAspect)
            targetHeight = bufferHeight
        }

        let xOffset = (bufferWidth - targetWidth) / 2
        let yOffset = (bufferHeight - targetHeight) / 2

        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Recortar primero (en coordenadas del buffer landscape)
        let cropRect = CGRect(x: xOffset, y: yOffset, width: targetWidth, height: targetHeight)
        ciImage = ciImage.cropped(to: cropRect)

        // Ahora rotar
        ciImage = ciImage.oriented(.right)

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // Imagen recortada solo de la región central (para OCR más rápido)
    private func croppedCenterImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)

        // Capturar casi toda la pantalla para detectar alias en cualquier posición
        // Solo recortamos un pequeño margen en los bordes
        let cropWidth = Int(Double(bufferHeight) * 0.95)   // 95% del ancho (después de rotar)
        let cropHeight = Int(Double(bufferWidth) * 0.85)   // 85% del alto (después de rotar)

        let xOffset = (bufferHeight - cropWidth) / 2
        let yOffset = (bufferWidth - cropHeight) / 2

        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Recortar la región central (coordenadas del buffer landscape)
        let cropRect = CGRect(x: xOffset, y: yOffset, width: cropWidth, height: cropHeight)
        ciImage = ciImage.cropped(to: cropRect)

        // Rotar
        ciImage = ciImage.oriented(.right)

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
