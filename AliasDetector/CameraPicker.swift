import SwiftUI
import UIKit
import PhotosUI

struct CameraPicker: View {
    @Environment(\.dismiss) private var dismiss
    var onImagePicked: (UIImage) -> Void

    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    var body: some View {
        ZStack {
            // Camera view
            CameraViewController(onImagePicked: { image in
                onImagePicked(image)
                dismiss()
            }, onCancel: {
                dismiss()
            })
            .ignoresSafeArea()

            // Gallery button overlay
            VStack {
                Spacer()
                HStack {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18))
                            Text("Galería")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                    }
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 140)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        onImagePicked(image)
                        dismiss()
                    }
                }
            }
        }
    }
}

// UIKit camera controller
struct CameraViewController: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraViewController

        init(_ parent: CameraViewController) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}
