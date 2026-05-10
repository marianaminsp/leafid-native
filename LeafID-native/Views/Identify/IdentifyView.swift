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
    @State private var runningGeminiStressTest = false
    @State private var showGeminiStressResult = false
    @State private var geminiStressSummary = ""

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
                            handleOpenCameraAction()
                        }

                        SecondaryActionButton(title: "Choose from library", systemImage: "arrow.up.doc") {
                            if ImagePickerAvailability.photoLibraryAvailable() {
                                showLibraryPicker = true
                            }
                        }

                        #if DEBUG
                        SecondaryActionButton(
                            title: runningGeminiStressTest ? "Running Gemini Random 5..." : "Run Gemini Random 5",
                            systemImage: "sparkles"
                        ) {
                            guard !runningGeminiStressTest else { return }
                            runningGeminiStressTest = true
                            Task {
                                let lines = await BotanyService.runGeminiStressTest()
                                await MainActor.run {
                                    runningGeminiStressTest = false
                                    geminiStressSummary = lines.joined(separator: "\n")
                                    showGeminiStressResult = true
                                }
                            }
                        }
                        #endif
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        #if DEBUG
        .alert("Gemini Random 5", isPresented: $showGeminiStressResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(geminiStressSummary.isEmpty ? "No response lines produced." : geminiStressSummary)
        }
        #endif
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
