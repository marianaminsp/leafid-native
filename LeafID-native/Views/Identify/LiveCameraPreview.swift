//
//  LiveCameraPreview.swift
//  LeafID-native
//
//  AVFoundation live preview + photo capture for ScannerView.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

final class LeafIDCameraSession: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    @Published private(set) var isConfigured = false
    @Published private(set) var isSessionRunning = false
    @Published private(set) var configurationError: String?

    private var continuation: CheckedContinuation<Data?, Never>?

    func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            configurationError = String(localized: "No camera available.")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            isConfigured = true
            configurationError = nil
        } catch {
            configurationError = error.localizedDescription
        }
    }

    func start() {
        guard isConfigured else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }

    func stop() {
        session.stopRunning()
        DispatchQueue.main.async { [weak self] in
            self?.isSessionRunning = false
        }
    }

    func capturePhoto() async -> Data? {
        guard isConfigured else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<Data?, Never>) in
            self.continuation = cont
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func finishCapture(with data: Data?) {
        continuation?.resume(returning: data)
        continuation = nil
    }
}

extension LeafIDCameraSession: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if error != nil {
            finishCapture(with: nil)
            return
        }
        finishCapture(with: photo.fileDataRepresentation())
    }
}

final class PreviewHostView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct LiveCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewHostView {
        let v = PreviewHostView()
        v.previewLayer.session = session
        v.previewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PreviewHostView, context: Context) {
        uiView.previewLayer.session = session
    }
}
