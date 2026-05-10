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
    let latitude: Double?
    let longitude: Double?
    let locality: String?
}

struct IdentifyView: View {
    @EnvironmentObject private var herbarium: HerbariumViewModel

    @AppStorage("profile.scans_count") private var scansCount = 0
    @AppStorage("profile.is_premium") private var isPremium = false

    @State private var activeScanSession: ScanSession?
    @State private var scanOutcome: IdentifyScanOutcome?

    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var cameraUnavailable = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            LeafIDTheme.surface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: LeafIDTheme.space24) {
                    BoutiqueHeader(
                        layout: .stacked(plainTop: String(localized: "The"), accentBottom: String(localized: "Scan")),
                        subtitle: String(localized: "Capture a specimen — the Botanist consults the archive.")
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
                                    Text(String(localized: "Use the camera or your photo library to identify a plant."))
                                        .font(LeafIDFont.manrope(size: 14, weight: .medium))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                                        .padding(.horizontal, LeafIDTheme.space24)
                                }
                            }
                            .padding(.horizontal, LeafIDTheme.space4)

                        LeafPrimaryButton(title: String(localized: "Open camera")) {
                            handleOpenCameraAction()
                        }

                        SecondaryActionButton(title: String(localized: "Choose from library"), systemImage: "arrow.up.doc") {
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
        .alert(String(localized: "Camera unavailable"), isPresented: $cameraUnavailable) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "Use Choose from library on Simulator, or run on an iPhone."))
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            ScannerView(
                onClose: { showCameraPicker = false },
                onCaptured: { data, lat, lon, locality in
                    showCameraPicker = false
                    activeScanSession = ScanSession(
                        jpegData: data,
                        latitude: lat,
                        longitude: lon,
                        locality: locality
                    )
                }
            )
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePickerBridge(
                sourceType: .photoLibrary,
                isPresented: $showLibraryPicker,
                onPickedJPEG: { data, coordinate, locality in
                    activeScanSession = ScanSession(
                        jpegData: data,
                        latitude: coordinate?.latitude,
                        longitude: coordinate?.longitude,
                        locality: locality
                    )
                }
            )
        }
        .fullScreenCover(item: $activeScanSession, onDismiss: {}) { session in
            ScannerView(
                captureJPEGData: session.jpegData,
                onClose: { activeScanSession = nil },
                onComplete: { result, data in
                    activeScanSession = nil
                    let payload = IdentifyScanOutcome(
                        result: result,
                        imageJPEGData: data,
                        latitude: session.latitude,
                        longitude: session.longitude,
                        locality: session.locality
                    )
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
                captureLatitude: outcome.latitude,
                captureLongitude: outcome.longitude,
                captureLocality: outcome.locality,
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

    private func canUserScan() -> Bool {
        isPremium || ProfileStatsLocalStore.scansForFreeTierGate(appStorageQuota: scansCount) < 3
    }

    private func handleOpenCameraAction() {
        guard canUserScan() else {
            showPaywall = true
            return
        }
        if ImagePickerAvailability.cameraAvailable() {
            showCameraPicker = true
        } else {
            cameraUnavailable = true
        }
    }
}
