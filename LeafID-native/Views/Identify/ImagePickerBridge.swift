//
//  ImagePickerBridge.swift
//  LeafID-native
//
//  Camera and photo library both use `UIImagePickerController` so the user gets a `UIImage` directly.
//  This avoids PHPicker → `PHAsset` / `PAMediaConversionService` export failures common on Simulator.
//

import SwiftUI
import UIKit

// MARK: - JPEG encoding + size cap for Plant.id / Supabase

private enum PickedImageEncoding {
    /// Longest edge in pixels after scaling (keeps uploads reasonable).
    private static let maxPixelDimension: CGFloat = 2048
    private static let jpegQuality: CGFloat = 0.82

    static func jpegData(from image: UIImage) -> Data? {
        let prepared = normalizedForUpload(image)
        if let d = prepared.jpegData(compressionQuality: jpegQuality) { return d }
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(1, prepared.scale)
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: prepared.size, format: format)
        let flattened = renderer.image { _ in
            prepared.draw(in: CGRect(origin: .zero, size: prepared.size))
        }
        return flattened.jpegData(compressionQuality: jpegQuality)
    }

    private static func normalizedForUpload(_ image: UIImage) -> UIImage {
        let pixelW: CGFloat
        let pixelH: CGFloat
        if let cg = image.cgImage {
            pixelW = CGFloat(cg.width)
            pixelH = CGFloat(cg.height)
        } else {
            pixelW = image.size.width * image.scale
            pixelH = image.size.height * image.scale
        }
        let longest = max(pixelW, pixelH)
        guard longest > maxPixelDimension else { return image }

        let ratio = maxPixelDimension / longest
        let newW = max(1, floor(pixelW * ratio))
        let newH = max(1, floor(pixelH * ratio))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newW, height: newH), format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: newW, height: newH))
        }
    }
}

// MARK: - Camera & photo library (UIKit)

struct ImagePickerBridge: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var isPresented: Bool
    var onPickedJPEG: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = sourceType == .camera ? .fullScreen : .pageSheet
        picker.allowsEditing = false
        picker.mediaTypes = ["public.image"]
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePickerBridge

        init(parent: ImagePickerBridge) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image: UIImage?
            if let edited = info[.editedImage] as? UIImage {
                image = edited
            } else {
                image = info[.originalImage] as? UIImage
            }

            if let image, let data = PickedImageEncoding.jpegData(from: image) {
                parent.onPickedJPEG(data)
            }
            parent.isPresented = false
        }
    }
}

enum ImagePickerAvailability {
    static func cameraAvailable() -> Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    static func photoLibraryAvailable() -> Bool {
        UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
}
