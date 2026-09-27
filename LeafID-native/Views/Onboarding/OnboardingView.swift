//
//  OnboardingView.swift
//  LeafID-native
//
//  First-launch, pre-auth intro: an animated cover slide (three lines, one
//  fixed leaf mark, no loop) followed by two tap-through beats and a real
//  sign-in screen that reuses AuthViewModel's Google OAuth flow.
//

import SwiftUI
import PostHog

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
        PostHogSDK.shared.capture("onboarding_screen_advanced", properties: [
            "from_screen": step,
            "to_screen": step + 1,
            "timestamp": Date().timeIntervalSince1970
        ])
        step += 1
    }

    private func signInWithGoogle() {
        guard let url = authViewModel.googleOAuthURL() else {
            authViewModel.lastError = String(localized: "Supabase is not configured. Add SUPABASE_URL (quoted) and SUPABASE_ANON_KEY in Secrets.local.xcconfig.")
            onFinished()
            return
        }
        authViewModel.lastError = nil
        PostHogSDK.shared.capture("onboarding_google_signin_initiated", properties: [
            "flow": "onboarding",
            "timestamp": Date().timeIntervalSince1970
        ])
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
            LeafIDIcon(kind: .icon2_0, style: .outline, size: 20, weight: 2.5, color: LeafIDTheme.primary)
                .padding(.top, 0)
                .padding(.bottom, 20)

            ZStack(alignment: .topLeading) {
                coverLine(0, headline: String(localized: "You just noticed something."))
                coverLine(1, headline: String(localized: "Look closer at what it holds."))
                coverLine(
                    2,
                    headline: String(localized: "The world expands when you uncover the deep behind the green."),
                    bodyText: String(localized: "Start with the leaf in front of you.")
                )
            }
            .frame(minHeight: 170, alignment: .topLeading)

            HStack(spacing: 6) {
                ForEach(0 ..< 3) { index in
                    Capsule()
                        .fill(index <= beat ? LeafIDTheme.primary : LeafIDTheme.outlineVariant.opacity(0.5))
                        .frame(width: index == beat ? 16 : 6, height: 6)
                }
            }
            .padding(.top, 20)

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
            if index == 0 {
                (Text("You just noticed ")
                    .font(LeafIDFont.plusJakarta(size: 32, weight: .bold))
                    .tracking(-0.01)
                + Text("something")
                    .font(LeafIDFont.plusJakarta(size: 32, weight: .bold).italic())
                    .tracking(-0.01)
                + Text(".")
                    .font(LeafIDFont.plusJakarta(size: 32, weight: .bold))
                    .tracking(-0.01))
                .foregroundColor(LeafIDTheme.onSurface)
            } else if index == 2 {
                (Text("The world expands when you uncover the deep behind the ")
                    .font(LeafIDFont.plusJakarta(size: 32, weight: .bold))
                    .tracking(-0.01)
                + Text("green")
                    .font(LeafIDFont.plusJakarta(size: 32, weight: .bold).italic())
                    .tracking(-0.01)
                + Text(".")
                    .font(LeafIDFont.plusJakarta(size: 32, weight: .bold))
                    .tracking(-0.01))
                .foregroundColor(LeafIDTheme.onSurface)
            } else {
                LeafIDTypography.displayTitle(headline)
            }
            if let bodyText {
                Text(bodyText)
                    .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                    .foregroundColor(LeafIDTheme.onSurfaceVariant)
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
        try? await Task.sleep(for: .seconds(2.8))
        withAnimation(.easeInOut(duration: 0.52)) { beat = 1 }
        try? await Task.sleep(for: .seconds(2.8))
        withAnimation(.easeInOut(duration: 0.52)) { beat = 2 }
        try? await Task.sleep(for: .seconds(1.2))
        withAnimation(.easeInOut(duration: 0.48)) { showContinue = true }
    }
}

// MARK: - Screens 2–3: tap-through beats with auto-advance

private struct OnboardingBeatScreen: View {
    let eyebrow: String
    let headline: String
    let bodyText: String
    let pageIndex: Int
    let primaryTitle: String
    var onPrimary: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    OnboardingEyebrow(eyebrow)
                        .opacity(showContent ? 1 : 0)
                    LeafIDTypography.displayTitle(headline)
                        .padding(.top, 20)
                        .offset(y: showContent ? 0 : 8)
                        .opacity(showContent ? 1 : 0)
                    Text(bodyText)
                        .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        .padding(.top, 20)
                        .offset(y: showContent ? 0 : 12)
                        .opacity(showContent ? 1 : 0)
                }
                VStack(alignment: .center) {
                    let heroIcon: LeafIDIcon.Kind = pageIndex == 1 ? .icon2_2 : .icon3_14
                    LeafIDIcon(kind: heroIcon, style: .filled, size: pageIndex == 1 ? 48 : 56, color: LeafIDTheme.primary)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                    Spacer()
                }
            }

            Spacer(minLength: LeafIDTheme.space32)

            OnboardingPageDots(total: 4, activeIndex: pageIndex)
                .padding(.bottom, 20)

            OnboardingGhostButton(title: primaryTitle, action: onPrimary)
        }
        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
        .padding(.bottom, LeafIDTheme.space32)
        .task {
            guard !reduceMotion else {
                showContent = true
                return
            }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeInOut(duration: 0.52)) {
                showContent = true
            }
            try? await Task.sleep(for: .seconds(3.2))
            withAnimation(.easeInOut(duration: 0.45)) {
                onPrimary()
            }
        }
    }
}

// MARK: - Screen 4: real sign-in

private struct OnboardingSignInScreen: View {
    var onContinueWithGoogle: () -> Void
    var onNotNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
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
                }
                Spacer(minLength: LeafIDTheme.space16)
                LeafIDIcon(kind: .icon2_3, style: .filled, size: 48, color: LeafIDTheme.primary.opacity(0.6))
            }

            Spacer(minLength: LeafIDTheme.space32)

            HStack(spacing: LeafIDTheme.space10) {
                Circle()
                    .fill(LeafIDTheme.primary)
                    .frame(width: 8, height: 8)
                Text(String(localized: "Archdruid"))
                    .font(LeafIDFont.manrope(size: 15, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurface)
            }

            Spacer(minLength: LeafIDTheme.space32)

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
