//
//  ImagePickerBridge.swift
//  LeafID-native
//
//  Camera and photo library both use `UIImagePickerController` so the user gets a `UIImage` directly.
//  This avoids PHPicker → `PHAsset` / `PAMediaConversionService` export failures common on Simulator.
//

import CoreLocation
import ImageIO
import SwiftUI
import UIKit

// MARK: - JPEG encoding + size cap for Plant.id / Supabase

enum PickedImageEncoding {
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
    /// Third value is reverse-geocoded locality (EXIF GPS) or device GPS + locality when `sourceType == .camera`.
    var onPickedJPEG: (Data, CLLocationCoordinate2D?, String?) -> Void

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

            let parent = self.parent
            parent.isPresented = false

            Task { @MainActor in
                guard let image, let data = PickedImageEncoding.jpegData(from: image) else { return }
                let exifCoordinate = PickedImageMetadata.coordinate(from: info)
                let useDevice = parent.sourceType == .camera
                #if canImport(CoreLocation)
                let (coordinate, locality) = await CapturePickLocationEngine.coordinateAndLocality(
                    exifCoordinate: exifCoordinate,
                    useDeviceFallback: useDevice
                )
                #else
                let (coordinate, locality) = (exifCoordinate, nil as String?)
                #endif
                parent.onPickedJPEG(data, coordinate, locality)
            }
        }
    }
}

private enum PickedImageMetadata {
    static func coordinate(from info: [UIImagePickerController.InfoKey: Any]) -> CLLocationCoordinate2D? {
        if let metadata = info[.mediaMetadata] as? [String: Any],
           let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let parsed = parseGPSDictionary(gps) {
            return parsed
        }
        if let url = info[.imageURL] as? URL,
           let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
           let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            return parseGPSDictionary(gps)
        }
        return nil
    }

    private static func parseGPSDictionary(_ gps: [String: Any]) -> CLLocationCoordinate2D? {
        guard let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double
        else { return nil }
        let latRef = (gps[kCGImagePropertyGPSLatitudeRef as String] as? String)?.uppercased() ?? "N"
        let lonRef = (gps[kCGImagePropertyGPSLongitudeRef as String] as? String)?.uppercased() ?? "E"
        let signedLat = latRef == "S" ? -lat : lat
        let signedLon = lonRef == "W" ? -lon : lon
        return CLLocationCoordinate2D(latitude: signedLat, longitude: signedLon)
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
