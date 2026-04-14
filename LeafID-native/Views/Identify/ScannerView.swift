//
//  ScannerView.swift
//  LeafID-native
//
//  `docs/ui-screens/scanning_leaf_animation.png` — full-bleed photo, frosted reticle panel, top chrome, density bar.
//  Tokens: `design_system_build` (surface, primary, outline-variant ghost edges, Manrope labels).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ScannerView: View {
    let captureJPEGData: Data
    var onClose: () -> Void
    var onComplete: (IdentifyPreviewResult, Data) -> Void

    @State private var failedMessage: String?
    @State private var densityProgress: Double = 0.06
    @State private var flashArmed = false

    private static let minimumAnalyzeNanoseconds: UInt64 = 2_900_000_000
    private static let completionHoldNanoseconds: UInt64 = 450_000_000

    #if canImport(UIKit)
    private var captureImage: UIImage? {
        UIImage(data: captureJPEGData)
    }
    #endif

    var body: some View {
        GeometryReader { geo in
            let reticleW = min(geo.size.width * 0.86, 360)
            let reticleH = reticleW * 1.12

            ZStack {
                #if canImport(UIKit)
                Group {
                    if let captureImage {
                        Image(uiImage: captureImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .ignoresSafeArea()
                    } else {
                        LeafIDTheme.surface
                    }
                }
                #else
                LeafIDTheme.surface
                #endif

                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            ModalCloseButton(action: onClose)
                            Spacer(minLength: 0)
                            GlassChromeCircleButton(
                                systemImage: "bolt.fill",
                                accessibilityLabel: flashArmed ? "Flash on" : "Flash off"
                            ) {
                                flashArmed.toggle()
                            }
                        }
                        GlassScanHeaderPill(title: "Analyzing leaf…", showsStatusDot: true)
                    }
                    .padding(.top, geo.safeAreaInsets.top + LeafIDTheme.space8)
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)

                    Spacer(minLength: LeafIDTheme.space12)

                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.thickMaterial)
                            .frame(width: reticleW, height: reticleH)
                            .background {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(LeafIDTheme.surface.opacity(0.08))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.18), lineWidth: 1)
                            }

                        ScanReticleFrame()
                            .padding(.horizontal, LeafIDTheme.space16)
                            .padding(.vertical, LeafIDTheme.space20)
                    }
                    .frame(width: reticleW, height: reticleH)

                    Spacer(minLength: LeafIDTheme.space16)

                    ScanningDensityProgress(progress: densityProgress)
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)

                    if let failedMessage {
                        Text(failedMessage)
                            .font(LeafIDFont.manrope(size: 13, weight: .medium))
                            .foregroundStyle(LeafIDTheme.primary.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                            .padding(.top, LeafIDTheme.space12)
                    }

                    Spacer(minLength: geo.safeAreaInsets.bottom + LeafIDTheme.space12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .task {
            await runWithProgressAnimation()
        }
    }

    private func runWithProgressAnimation() async {
        let progressTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(.easeOut(duration: 0.22)) {
                    densityProgress = min(0.94, densityProgress + 0.014)
                }
            }
        }

        defer { progressTask.cancel() }

        let b64 = captureJPEGData.base64EncodedString()
        do {
            async let apiResult = try BotanyService.identifyPlantWithAI(imageBase64: b64)
            try await Task.sleep(nanoseconds: Self.minimumAnalyzeNanoseconds)
            let result = try await apiResult

            await MainActor.run {
                progressTask.cancel()
                withAnimation(.easeOut(duration: 0.4)) {
                    densityProgress = 1
                }
            }

            try await Task.sleep(nanoseconds: Self.completionHoldNanoseconds)

            await MainActor.run {
                onComplete(result, captureJPEGData)
            }
        } catch {
            await MainActor.run {
                progressTask.cancel()
                failedMessage = "Couldn’t reach the botanist. Try again."
            }
        }
    }
}
