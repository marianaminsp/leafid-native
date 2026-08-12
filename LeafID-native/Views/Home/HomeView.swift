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
                HStack(spacing: LeafIDTheme.space10) {
                    Image(systemName: "arrow.up.square")
                        .font(.system(size: 16, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(LeafIDTheme.primary)
                    Text(String(localized: "Upload from Gallery"))
                        .font(LeafIDFont.manrope(size: 15, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LeafIDTheme.space10)
            .padding(.horizontal, LeafIDTheme.space16)
            // surfaceContainerHigh still read as barely-there against surface — bumped a
            // step further, same reasoning as the Last Found card treatment.
            .background(LeafIDTheme.surfaceContainerHighest)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.32), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HomeEmptyLastFoundCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space12) {
            RoundedRectangle(cornerRadius: LeafIDTheme.radiusSpecimenThumb, style: .continuous)
                .fill(LeafIDTheme.surfaceContainerHighest)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(LeafIDTheme.primary.opacity(0.35))
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                Text(String(localized: "Get Started"))
                    .font(LeafIDFont.manrope(size: 10, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(LeafIDTheme.primary)
                    .textCase(.uppercase)
                Text(String(localized: "Save a specimen to your Herbarium"))
                    .font(LeafIDFont.plusJakarta(size: 16, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(LeafIDTheme.space12)
        // surfaceContainerLow (0x10150C) was barely distinguishable from the page's own
        // surface (0x0B0F08) — bumped a step for a background that actually reads as a card.
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.25), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct HomeView: View {
    @EnvironmentObject private var herbarium: HerbariumViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

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
        let base: String
        switch h {
        case 5 ..< 12: base = String(localized: "Good Morning")
        case 12 ..< 17: base = String(localized: "Good Afternoon")
        default: base = String(localized: "Good Evening")
        }
        // Skip the fallback placeholder name — greeting "Good Morning, The Druid" to
        // everyone who hasn't set a real name isn't actually personalized.
        let name = authViewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != String(localized: "The Druid") else { return base }
        return "\(base), \(name)"
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
            .accessibilityLabel("\(String(localized: "Last Found")), \(specimen.commonName)")
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
                        Text(String(localized: "Ready to explore nature?"))
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

                    VStack(spacing: 12) {
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
                        // Visual nudge only — keeps Scan button anchored in its current spot
                        // because .offset does not affect SwiftUI layout (sibling Spacers unchanged).
                        .offset(y: 12)
                    }

                    Spacer(minLength: 0)

                    homeLastFoundSection
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                        // 8pt above the bottom layout safe area when Home is under MainTabView’s
                        // bottom safeAreaInset (top of tab bar reserve). Tab bar position unchanged.
                        .padding(.bottom, LeafIDTheme.space8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .preferredColorScheme(.dark)
        .alert(String(localized: "Camera unavailable"), isPresented: $cameraUnavailable) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "This device has no camera (e.g. Simulator). Use Upload from Gallery or run on a physical iPhone."))
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standalone Home (no tab bar) — useful for content layout review.
            HomeView()
                .previewDevice("iPhone 15")
                .previewDisplayName("Home — iPhone 15 (no tab bar)")

            // Wrapped in MainTabView — verifies Last Found spacing above tab reserve and horizontal alignment with tab gutter across sizes.
            MainTabView()
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("With Tab Bar — iPhone SE")

            MainTabView()
                .previewDevice("iPhone 15")
                .previewDisplayName("With Tab Bar — iPhone 15")

            MainTabView()
                .previewDevice("iPhone 15 Pro Max")
                .previewDisplayName("With Tab Bar — iPhone 15 Pro Max")
        }
        .environmentObject(HerbariumViewModel())
        .environmentObject(AuthViewModel())
    }
}
