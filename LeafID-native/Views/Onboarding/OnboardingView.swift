//
//  OnboardingView.swift
//  LeafID-native
//
//  First-launch, pre-auth intro: an animated cover slide (three lines, one
//  fixed leaf mark, no loop) followed by two tap-through beats and a real
//  sign-in screen that reuses AuthViewModel's Google OAuth flow.
//

import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.openURL) private var openURL
    @State private var step = 0

    var body: some View {
        ZStack {
            LeafIDTheme.surface.ignoresSafeArea()

            Group {
                switch step {
                case 0:
                    OnboardingCoverScreen(onContinue: advance)
                case 1:
                    OnboardingBeatScreen(
                        eyebrow: String(localized: "HOW IT WORKS"),
                        headline: String(localized: "Point. Capture. Reveal the depth."),
                        bodyText: String(localized: "The species, the family, the story most people walk past."),
                        pageIndex: 1,
                        primaryTitle: String(localized: "Next"),
                        onPrimary: advance
                    )
                case 2:
                    OnboardingBeatScreen(
                        eyebrow: String(localized: "YOUR HERBARIUM"),
                        headline: String(localized: "Treasure the moment, build your living archive."),
                        bodyText: String(localized: "Every discovery adds another layer — yours to keep, yours to revisit."),
                        pageIndex: 2,
                        primaryTitle: String(localized: "Next"),
                        onPrimary: advance
                    )
                default:
                    OnboardingSignInScreen(
                        onContinueWithGoogle: signInWithGoogle,
                        onNotNow: onFinished
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .leading))
            ))
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private func advance() {
        step += 1
    }

    private func signInWithGoogle() {
        guard let url = authViewModel.googleOAuthURL() else {
            authViewModel.lastError = String(localized: "Supabase is not configured. Add SUPABASE_URL (quoted) and SUPABASE_ANON_KEY in Secrets.local.xcconfig.")
            onFinished()
            return
        }
        authViewModel.lastError = nil
        openURL(url)
        onFinished()
    }
}

// MARK: - Screen 1: animated cover

private struct OnboardingCoverScreen: View {
    var onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var beat = 0
    @State private var showContinue = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Circle()
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.4), lineWidth: 1)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(LeafIDTheme.primary)
                }

            ZStack(alignment: .topLeading) {
                coverLine(0, headline: String(localized: "You just noticed something."))
                coverLine(1, headline: String(localized: "Look closer at what it holds."))
                coverLine(
                    2,
                    headline: String(localized: "The world expands when you uncover the history behind the green."),
                    bodyText: String(localized: "Start with the leaf in front of you.")
                )
            }
            .padding(.top, LeafIDTheme.space20)
            .frame(minHeight: 170, alignment: .topLeading)

            HStack(spacing: 6) {
                ForEach(0 ..< 3) { index in
                    Capsule()
                        .fill(index <= beat ? LeafIDTheme.primary : LeafIDTheme.outlineVariant.opacity(0.5))
                        .frame(width: index == beat ? 16 : 6, height: 6)
                }
            }
            .padding(.top, LeafIDTheme.space16)

            Spacer(minLength: LeafIDTheme.space24)

            if showContinue {
                LeafPrimaryButton(title: String(localized: "Continue"), useSolidPrimaryFill: true, action: onContinue)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
        .padding(.bottom, LeafIDTheme.space32)
        .task { await runSequence() }
    }

    @ViewBuilder
    private func coverLine(_ index: Int, headline: String, bodyText: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            LeafIDTypography.displayTitle(headline)
            if let bodyText {
                Text(bodyText)
                    .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            }
        }
        .opacity(beat == index ? 1 : 0)
        .offset(y: beat == index ? 0 : (beat > index ? -8 : 8))
    }

    private func runSequence() async {
        guard !reduceMotion else {
            beat = 2
            showContinue = true
            return
        }
        try? await Task.sleep(for: .seconds(3.5))
        withAnimation(.easeInOut(duration: 0.5)) { beat = 1 }
        try? await Task.sleep(for: .seconds(3.5))
        withAnimation(.easeInOut(duration: 0.5)) { beat = 2 }
        try? await Task.sleep(for: .seconds(1.6))
        withAnimation(.easeInOut(duration: 0.5)) { showContinue = true }
    }
}

// MARK: - Screens 2–3: tap-through beats sharing one layout

private struct OnboardingBeatScreen: View {
    let eyebrow: String
    let headline: String
    let bodyText: String
    let pageIndex: Int
    let primaryTitle: String
    var onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingEyebrow(eyebrow)
            LeafIDTypography.displayTitle(headline)
                .padding(.top, LeafIDTheme.space12)
            Text(bodyText)
                .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .padding(.top, LeafIDTheme.space12)

            Spacer(minLength: LeafIDTheme.space24)

            OnboardingPageDots(total: 4, activeIndex: pageIndex)
                .padding(.bottom, LeafIDTheme.space16)

            OnboardingGhostButton(title: primaryTitle, action: onPrimary)
        }
        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
        .padding(.bottom, LeafIDTheme.space32)
    }
}

// MARK: - Screen 4: real sign-in

private struct OnboardingSignInScreen: View {
    var onContinueWithGoogle: () -> Void
    var onNotNow: () -> Void

    private let ranks = ["Wandering Seed", "Forest Sprout", "Oak Guardian", "Archdruid"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingEyebrow(String(localized: "THE PATH"))
            Text(String(localized: "Wandering Seed to Archdruid."))
                .font(LeafIDFont.plusJakarta(size: 26, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(LeafIDTheme.onSurface)
                .padding(.top, LeafIDTheme.space12)
            Text(String(localized: "Stay curious, and even the forest starts to notice."))
                .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .padding(.top, LeafIDTheme.space12)

            VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
                ForEach(Array(ranks.enumerated()), id: \.offset) { index, rank in
                    HStack(spacing: LeafIDTheme.space10) {
                        Circle()
                            .fill(index == ranks.count - 1 ? LeafIDTheme.primary : LeafIDTheme.outlineVariant)
                            .frame(width: 8, height: 8)
                        Text(String(localized: String.LocalizationValue(rank)))
                            .font(LeafIDFont.manrope(size: 15, weight: index == ranks.count - 1 ? .semibold : .medium))
                            .foregroundStyle(index == ranks.count - 1 ? LeafIDTheme.onSurface : LeafIDTheme.onSurfaceVariant)
                    }
                    if index < ranks.count - 1 {
                        Rectangle()
                            .fill(LeafIDTheme.outlineVariant)
                            .frame(width: 1, height: 12)
                            .padding(.leading, 3.5)
                    }
                }
            }
            .padding(.top, LeafIDTheme.space24)

            Spacer(minLength: LeafIDTheme.space24)

            VStack(spacing: LeafIDTheme.space10) {
                LeafPrimaryButton(
                    title: String(localized: "Continue with Google"),
                    useSolidPrimaryFill: true,
                    action: onContinueWithGoogle
                )
                OnboardingGhostButton(title: String(localized: "Not now"), action: onNotNow)
            }
        }
        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
        .padding(.bottom, LeafIDTheme.space32)
    }
}

// MARK: - Shared pieces

private struct OnboardingEyebrow: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(LeafIDFont.manrope(size: LeafIDTheme.botanicalFrontEyebrowSize, weight: .bold))
            .tracking(LeafIDTheme.botanicalFrontEyebrowTracking)
            .foregroundStyle(LeafIDTheme.primary)
    }
}

private struct OnboardingPageDots: View {
    let total: Int
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< total, id: \.self) { index in
                Capsule()
                    .fill(index == activeIndex ? LeafIDTheme.primary : LeafIDTheme.outlineVariant.opacity(0.5))
                    .frame(width: index == activeIndex ? 16 : 6, height: 6)
            }
        }
    }
}

private struct OnboardingGhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            LeafIDHaptics.impact(.light)
            action()
        } label: {
            Text(title)
                .font(LeafIDFont.manrope(size: 15, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LeafIDTheme.space12)
                .overlay {
                    RoundedRectangle(cornerRadius: LeafIDTheme.radiusPrimaryButton, style: .continuous)
                        .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.5), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
