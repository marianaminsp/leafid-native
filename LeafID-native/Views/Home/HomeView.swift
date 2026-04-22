//
//  HomeView.swift
//  LeafID-native
//
//  Layout and chrome aligned to `docs/ui-screens/Homepage.png`; colors/type from `design_system_build`.
//

import SwiftUI

private struct ScanFlowOutcome: Identifiable {
    let id = UUID()
    let result: IdentifyPreviewResult
    let imageJPEGData: Data?
    let latitude: Double?
    let longitude: Double?
    let locality: String?
}

/// Homepage.png — wide capsule, dark charcoal fill, lime upload glyph, white label.
private struct HomeUploadGalleryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: LeafIDTheme.space12) {
                    Image(systemName: "arrow.up.square")
                        .font(.system(size: 18, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(LeafIDTheme.primary)
                    Text("Upload from Gallery")
                        .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LeafIDTheme.space14)
            .padding(.horizontal, LeafIDTheme.space20)
            .background(LeafIDTheme.surfaceContainerHigh)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.22), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HomeEmptyLastFoundCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space20) {
            RoundedRectangle(cornerRadius: LeafIDTheme.radiusSpecimenThumb, style: .continuous)
                .fill(LeafIDTheme.surfaceContainerHigh)
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(LeafIDTheme.primary.opacity(0.35))
                }

            VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                Text("Last Found")
                    .font(LeafIDFont.manrope(size: 10, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(LeafIDTheme.primary)
                    .textCase(.uppercase)
                Text("Save a specimen to your Herbarium")
                    .font(LeafIDFont.plusJakarta(size: 17, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LeafIDTheme.outlineVariant.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(LeafIDTheme.space20)
        .background(LeafIDTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.15), lineWidth: 1)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var herbarium: HerbariumViewModel

    @AppStorage("profile.scans_count") private var scansCount = 0
    @AppStorage("profile.is_premium") private var isPremium = false

    @State private var activeScanSession: ScanSession?
    @State private var scanOutcome: ScanFlowOutcome?
    @State private var lastFoundImmersiveScan: Scan?

    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var cameraUnavailable = false
    @State private var showPaywall = false

    private var greetingTitle: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5 ..< 12: return "Good Morning"
        case 12 ..< 17: return "Good Afternoon"
        case 17 ..< 22: return "Good Evening"
        default: return "Good Evening"
        }
    }

    @ViewBuilder
    private var homeLastFoundSection: some View {
        if let specimen = herbarium.mostRecentSavedSpecimen {
            Button {
                lastFoundImmersiveScan = specimen
            } label: {
                CompactSpecimenCard(lastFound: specimen)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            // Hit testing matches the card silhouette (HIG: tappable area follows the visible control).
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .accessibilityLabel("Last found, \(specimen.commonName)")
            .accessibilityHint(String(localized: "Opens the full specimen card"))
        } else {
            HomeEmptyLastFoundCard()
                .frame(maxWidth: .infinity)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LeafIDTheme.surface.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: LeafIDTheme.space8) {
                        Text(greetingTitle)
                            .font(LeafIDFont.plusJakarta(size: 34, weight: .bold))
                            .tracking(-0.55)
                            .foregroundStyle(LeafIDTheme.onSurface)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.82)
                            .lineLimit(2)
                        Text("Ready to explore nature?")
                            .font(LeafIDFont.manrope(size: 16, weight: .medium))
                            .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.top, geo.safeAreaInsets.top + LeafIDTheme.space4)

                    Spacer(minLength: 0)

                    VStack(spacing: LeafIDTheme.space12) {
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            GalleryScanButton {
                                handleOpenCameraAction()
                            }
                            Spacer(minLength: 0)
                        }

                        HomeUploadGalleryButton {
                            if ImagePickerAvailability.photoLibraryAvailable() {
                                showLibraryPicker = true
                            }
                        }
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    }

                    Spacer(minLength: 0)

                    homeLastFoundSection
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                        .padding(.bottom, LeafIDTheme.space8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Camera unavailable", isPresented: $cameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device has no camera (e.g. Simulator). Use Upload from Gallery or run on a physical iPhone.")
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
                    let payload = ScanFlowOutcome(
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
        #if canImport(UIKit)
        .fullScreenCover(item: $lastFoundImmersiveScan, onDismiss: {}) { scan in
            BotanicalCardImmersiveView(
                scan: scan,
                preview: nil,
                onClose: { lastFoundImmersiveScan = nil }
            )
        }
        #endif
    }

    private func canUserScan() -> Bool {
        isPremium || scansCount < 3
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(HerbariumViewModel())
    }
}
