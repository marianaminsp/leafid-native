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

    @State private var activeScanSession: ScanSession?
    @State private var scanOutcome: ScanFlowOutcome?

    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var cameraUnavailable = false

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
            CompactSpecimenCard(lastFound: specimen)
                .frame(maxWidth: .infinity)
        } else {
            HomeEmptyLastFoundCard()
                .frame(maxWidth: .infinity)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            LeafIDTheme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
                    Text(greetingTitle)
                        .font(LeafIDFont.plusJakarta(size: 34, weight: .bold))
                        .tracking(-0.55)
                        .foregroundStyle(LeafIDTheme.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    Text("Ready to explore nature?")
                        .font(LeafIDFont.manrope(size: 16, weight: .medium))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                .padding(.top, LeafIDTheme.space12)

                Spacer(minLength: 0)

                homeLastFoundSection
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.bottom, LeafIDTheme.space8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .center) {
                VStack(spacing: LeafIDTheme.space20) {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        GalleryScanButton {
                            if ImagePickerAvailability.cameraAvailable() {
                                showCameraPicker = true
                            } else {
                                cameraUnavailable = true
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    HomeUploadGalleryButton {
                        if ImagePickerAvailability.photoLibraryAvailable() {
                            showLibraryPicker = true
                        }
                    }
                }
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Camera unavailable", isPresented: $cameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device has no camera (e.g. Simulator). Use Upload from Gallery or run on a physical iPhone.")
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
                    let payload = ScanFlowOutcome(result: result, imageJPEGData: data)
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(HerbariumViewModel())
    }
}
