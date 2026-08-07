//
//  BotanicalCardImageProcessor.swift
//  LeafID-native
//
//  On-device photo intervention for the Botanical Card hero image: a subject-aware crop,
//  auto exposure/contrast/vibrance leveling, and a subtle brand duotone grade. Deliberately
//  excludes background segmentation/cutout and heavy stylization (posterize/edge-extraction) —
//  the photo is the user's proof they found this plant; the frame carries the brand, not the pixels.
//
//  Vision's `VNGenerateForegroundInstanceMaskRequest` (subject lift) requires iOS 17+; this app's
//  deployment target is 16.4, so only `VNGenerateAttentionBasedSaliencyImageRequest` (iOS 13+) is used.
//

import Foundation

#if canImport(UIKit) && canImport(CoreImage) && canImport(Vision)
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

enum BotanicalCardImageProcessor {
    /// Longest edge for the derived card image — smaller than the raw capture cap (2048px, see
    /// `PickedImageEncoding`) since this is a stylized hero image, not the zoomable "proof" photo.
    private static let maxOutputDimension: CGFloat = 1440
    /// Portrait aspect the crop step targets; the view layer still `.scaledToFill()`s on top of this.
    private static let outputAspectRatio: CGFloat = 4.0 / 5.0
    private static let jpegQuality: CGFloat = 0.85

    /// GPU-backed, created once — a fresh `CIContext` per image is the classic CoreImage perf mistake.
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// Runs the full pipeline against a raw captured JPEG and returns the processed JPEG,
    /// or `nil` if the source can't be decoded. CPU/GPU-bound — call from a background context.
    static func makeCardImageJPEG(from sourceJPEGData: Data) -> Data? {
        guard let decoded = CIImage(data: sourceJPEGData, options: [.applyOrientationProperty: true]) else {
            return nil
        }

        var image = croppedToSalientSubject(decoded)
        image = downscaledIfNeeded(image)
        image = leveled(image)
        image = brandGraded(image)

        guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: jpegQuality)
    }

    // MARK: - Step 1: subject-aware crop

    private static func croppedToSalientSubject(_ image: CIImage) -> CIImage {
        let extent = image.extent
        guard extent.width > 1, extent.height > 1 else { return image }
        let subject = salientBoundingBox(in: image, extent: extent) ?? extent
        let targetRect = expandedToAspect(subject, boundedBy: extent)
        return image.cropped(to: targetRect)
    }

    /// Highest-attention region via Vision saliency, in pixel coordinates. `nil` when Vision finds
    /// nothing usable (flat/low-contrast image, or the request fails) — callers fall back to a
    /// full-extent "subject", which `expandedToAspect` turns into a plain center crop.
    private static func salientBoundingBox(in image: CIImage, extent: CGRect) -> CGRect? {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let observation = request.results?.first,
              let objects = observation.salientObjects, !objects.isEmpty
        else { return nil }

        var unioned: CGRect?
        for object in objects {
            let n = object.boundingBox // normalized, origin bottom-left
            let pixelRect = CGRect(
                x: extent.minX + n.minX * extent.width,
                y: extent.minY + n.minY * extent.height,
                width: n.width * extent.width,
                height: n.height * extent.height
            )
            unioned = unioned?.union(pixelRect) ?? pixelRect
        }
        return unioned
    }

    /// Expands `subject` to `outputAspectRatio`, centered on it, clamped to `bounds`, never tighter
    /// than 60% of the shorter source dimension (guards against a degenerate crop on a tiny/edge subject).
    private static func expandedToAspect(_ subject: CGRect, boundedBy bounds: CGRect) -> CGRect {
        let minSide = min(bounds.width, bounds.height) * 0.6
        var width = max(subject.width, minSide)
        var height = max(subject.height, minSide)
        if width / height > outputAspectRatio {
            height = width / outputAspectRatio
        } else {
            width = height * outputAspectRatio
        }
        width = min(width, bounds.width)
        height = min(height, bounds.height)

        var x = subject.midX - width / 2
        var y = subject.midY - height / 2
        x = max(bounds.minX, min(x, bounds.maxX - width))
        y = max(bounds.minY, min(y, bounds.maxY - height))
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func downscaledIfNeeded(_ image: CIImage) -> CIImage {
        let extent = image.extent
        let longest = max(extent.width, extent.height)
        guard longest > maxOutputDimension else { return image }
        let scale = maxOutputDimension / longest
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    // MARK: - Step 2: auto exposure / contrast / vibrance leveling

    /// Hand-rolled rather than `CIImage.autoAdjustmentFilters()` so the numeric targets stay
    /// tunable/consistent, matching the values validated in the Python/Pillow prototype.
    private static func leveled(_ image: CIImage) -> CIImage {
        var result = image

        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = result
        exposure.ev = 0.15
        result = exposure.outputImage ?? result

        let controls = CIFilter.colorControls()
        controls.inputImage = result
        controls.saturation = 1.05
        controls.contrast = 1.06
        result = controls.outputImage ?? result

        let vibrance = CIFilter.vibrance()
        vibrance.inputImage = result
        vibrance.amount = 0.35
        result = vibrance.outputImage ?? result

        return result.cropped(to: image.extent)
    }

    // MARK: - Step 3: brand duotone tint (the one deliberately "branded" step)

    /// Maps luminance through an ink→pale-mint gradient (`CIColorMap`), then blends that duotone
    /// back over the leveled photo at ~20% — a faint, uniform tint, not a stylized replace.
    private static func brandGraded(_ image: CIImage) -> CIImage {
        let extent = image.extent

        let gradient = CIFilter.linearGradient()
        gradient.point0 = CGPoint(x: 0, y: 0)
        gradient.point1 = CGPoint(x: 256, y: 0)
        gradient.color0 = CIColor(red: 0x0d / 255, green: 0x14 / 255, blue: 0x10 / 255) // ink shadow
        gradient.color1 = CIColor(red: 0xea / 255, green: 0xfb / 255, blue: 0xe4 / 255) // pale mint highlight
        guard let gradientImage = gradient.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 256, height: 1)) else {
            return image
        }

        let colorMap = CIFilter.colorMap()
        colorMap.inputImage = image
        colorMap.gradientImage = gradientImage
        guard let duotone = colorMap.outputImage?.cropped(to: extent) else { return image }

        // Scale the duotone's alpha to ~20% so it reads as a tint, not a full replace.
        let faded = duotone.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.20),
        ])

        let blend = CIFilter.sourceOverCompositing()
        blend.inputImage = faded
        blend.backgroundImage = image
        var result = blend.outputImage?.cropped(to: extent) ?? image

        let lift = CIFilter.colorControls()
        lift.inputImage = result
        lift.saturation = 1.08
        lift.contrast = 1.03
        result = lift.outputImage?.cropped(to: extent) ?? result

        return result
    }
}
#endif
