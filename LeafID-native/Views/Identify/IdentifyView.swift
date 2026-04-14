//
//  IdentifyView.swift
//  LeafID-native
//
//  Same scan pipeline as Home — `ScanSession` + `Homepage.png` / scanning / results patterns.
//

import SwiftUI

private struct IdentifyScanOutcome: Identifiable {
    let id = UUID()
    let result: IdentifyPreviewResult
    let imageJPEGData: Data?
}

struct IdentifyView: View {
    @EnvironmentObject private var herbarium: HerbariumViewModel

    @State private var activeScanSession: ScanSession?
    @State private var scanOutcome: IdentifyScanOutcome?

    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var cameraUnavailable = false

    var body: some View {
        ZStack {
            LeafIDTheme.surface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: LeafIDTheme.space24) {
                    BoutiqueHeader(
                        layout: .stacked(plainTop: "The", accentBottom: "Scan"),
                        subtitle: "Capture a specimen — the Botanist consults the archive."
                    )

                    VStack(spacing: LeafIDTheme.space16) {
                        RoundedRectangle(cornerRadius: LeafIDTheme.radiusSpecimenThumb, style: .continuous)
                            .fill(LeafIDTheme.specimenField)
                            .aspectRatio(3 / 4, contentMode: .fit)
                            .overlay {
                                VStack(spacing: LeafIDTheme.space12) {
                                    Image(systemName: "camera.aperture")
                                        .font(.system(size: 44, weight: .thin))
                                        .foregroundStyle(LeafIDTheme.primary.opacity(0.85))
                                    Text("Use the camera or your photo library to identify a plant.")
                                        .font(LeafIDFont.manrope(size: 14, weight: .medium))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                                        .padding(.horizontal, LeafIDTheme.space24)
                                }
                            }
                            .padding(.horizontal, LeafIDTheme.space4)

                        LeafPrimaryButton(title: "Open camera") {
                            if ImagePickerAvailability.cameraAvailable() {
                                showCameraPicker = true
                            } else {
                                cameraUnavailable = true
                            }
                        }

                        SecondaryActionButton(title: "Choose from library", systemImage: "arrow.up.doc") {
                            if ImagePickerAvailability.photoLibraryAvailable() {
                                showLibraryPicker = true
                            }
                        }
                    }
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                }
                .padding(.top, LeafIDTheme.headerTopInset)
                .padding(.bottom, LeafIDTheme.space28)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Camera unavailable", isPresented: $cameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Use Choose from library on Simulator, or run on an iPhone.")
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            ImagePickerBridge(
                sourceType: .camera,
                isPresented: $showCameraPicker,
                onPickedJPEG: { data in
                    activeScanSession = ScanSession(jpegData: data)
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePickerBridge(
                sourceType: .photoLibrary,
                isPresented: $showLibraryPicker,
                onPickedJPEG: { data in
                    activeScanSession = ScanSession(jpegData: data)
                }
            )
        }
        .fullScreenCover(item: $activeScanSession, onDismiss: {}) { session in
            ScannerView(
                captureJPEGData: session.jpegData,
                onClose: { activeScanSession = nil },
                onComplete: { result, data in
                    activeScanSession = nil
                    let payload = IdentifyScanOutcome(result: result, imageJPEGData: data)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        scanOutcome = payload
                    }
                }
            )
        }
        .fullScreenCover(item: $scanOutcome, onDismiss: {}) { outcome in
            ScanResultsView(
                result: outcome.result,
                imageJPEGData: outcome.imageJPEGData,
                onClose: { scanOutcome = nil },
                onScanAgain: {
                    scanOutcome = nil
                    if ImagePickerAvailability.cameraAvailable() {
                        showCameraPicker = true
                    } else {
                        showLibraryPicker = true
                    }
                }
            )
            .environmentObject(herbarium)
        }
    }
}
