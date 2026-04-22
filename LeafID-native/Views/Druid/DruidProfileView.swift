//
//  DruidProfileView.swift
//  LeafID-native
//
//  The Druid — passport-style identity & progression (PDR §2 / protocol Tab 4).
//

import SwiftUI

struct DruidProfileView: View {
    @StateObject private var viewModel = DruidProfileViewModel()
    @State private var showPaywall = false
    @State private var showCameraPicker = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                LeafIDTheme.deepForest.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: LeafIDTheme.space28) {
                        passportHeader
                        esenciaVitalCard
                        achievementsRow
                        bioPassportPanel
                        scannerOrCoffeeGate
                    }
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.top, LeafIDTheme.space12)
                    .padding(.bottom, 36)
                }

                if !viewModel.isLoggedIn {
                    loginOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task { await viewModel.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .druidAuthDidChange)) { _ in
            Task { await viewModel.refresh() }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            ScannerView(onClose: { showCameraPicker = false }, onCaptured: { _, _, _, _ in
                showCameraPicker = false
            })
        }
    }

    private var passportHeader: some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space20) {
            ZStack {
                Circle()
                    .fill(LeafIDTheme.passportAvatarGradient)
                    .frame(width: 88, height: 88)
                Text(initialGlyph)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: LeafIDTheme.space8) {
                Text(viewModel.realName)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                Text(viewModel.rankTitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(LeafIDTheme.slateMuted)
                if viewModel.isLoading {
                    StatusBadge(state: .loading)
                } else if viewModel.lastError != nil {
                    StatusBadge(state: .error)
                } else {
                    StatusBadge(state: .active)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(LeafIDTheme.space24)
        .background(
            RoundedRectangle(cornerRadius: LeafIDTheme.liquidGlassCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: LeafIDTheme.liquidGlassCornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            LeafIDTheme.leafGreen.opacity(0.35),
                            Color.white.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.liquidGlassCornerRadius, style: .continuous))
    }

    private var initialGlyph: String {
        let name = viewModel.profile?.displayName ?? "Druid"
        return String(name.prefix(1)).uppercased()
    }

    private var esenciaVitalCard: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            HStack {
                Text("Esencia Vital")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                if viewModel.isPremium {
                    Text("Unlimited")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafIDTheme.leafGreen)
                } else {
                    Text("\(viewModel.remainingScans) left")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafIDTheme.slateMuted)
                }
            }

            ProgressView(value: viewModel.energyProgress, total: 1)
                .tint(LeafIDTheme.leafGreen)
                .progressViewStyle(.linear)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)
                .clipShape(Capsule())

            Text(viewModel.isPremium ? "Premium energy unlocked." : "Free plan: 3 total scans")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(LeafIDTheme.slateMuted)
        }
        .padding(LeafIDTheme.space20)
        .liquidGlass()
    }

    private var achievementsRow: some View {
        HStack(spacing: LeafIDTheme.space10) {
            ForEach(Array(achievementSymbols.enumerated()), id: \.offset) { index, symbol in
                let lit = index < litAchievementCount
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(lit ? LeafIDTheme.leafGreen : LeafIDTheme.slateMuted.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LeafIDTheme.space10)
                    .background(LeafIDTheme.deepGreen.opacity(lit ? 0.8 : 0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var achievementSymbols: [String] {
        ["leaf.fill", "leaf.fill", "leaf.fill", "leaf.fill", "sparkles"]
    }

    private var litAchievementCount: Int {
        switch viewModel.scansCount {
        case 0: return 0
        case 1 ... 5: return 1
        case 6 ... 15: return 2
        case 16 ... 50: return 4
        default: return 5
        }
    }

    private var bioPassportPanel: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space14) {
            Text("Passport bio")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(LeafIDTheme.slateMuted)
            Text(viewModel.profile?.bio ?? "")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .tracking(0.25)
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space24)
        .liquidGlass()
    }

    private var scannerOrCoffeeGate: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            if viewModel.canUserScan() {
                LeafPrimaryButton(title: "Open scanner") {
                    showCameraPicker = true
                }
            } else {
                LeafPrimaryButton(title: "Buy me a Coffee") {
                    showPaywall = true
                }
            }
        }
    }

    private var loginOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                Text("Login Overlay")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Sign in with Google to unlock your Druid Passport.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LeafIDTheme.slateMuted)

                Button {
                    if let url = viewModel.googleSignInURL() {
                        openURL(url)
                    }
                    // Until OAuth callback wiring is completed, keep local state in sync for passport UX.
                    viewModel.completeLocalGoogleLoginDisplay()
                } label: {
                    HStack(spacing: LeafIDTheme.space10) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Continue with Google")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LeafIDTheme.space14)
                    .background(LeafIDTheme.leafGreen)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(LeafIDTheme.space24)
            .background(LeafIDTheme.surfaceContainerHigh)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.2), lineWidth: 1)
            }
            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
        }
    }
}
