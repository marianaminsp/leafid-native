//
//  DruidProfileView.swift
//  LeafID-native
//
//  The Druid — passport-style identity & progression (PDR §2 / protocol Tab 4).
//

import SwiftUI

struct DruidProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var herbarium: HerbariumViewModel
    @StateObject private var viewModel = DruidProfileViewModel()
    @State private var showPaywall = false
    /// Raw `UIScrollView.contentOffset.y` — 0 at rest, positive as the user scrolls down.
    @State private var rawScrollOffsetY: CGFloat = 0
    @Environment(\.openURL) private var openURL

    private var headerCollapseProgress: CGFloat {
        let y = rawScrollOffsetY
        let threshold: CGFloat = 96
        if y <= 0 { return 0 }
        return min(1, y / threshold)
    }

    private var druidTitlePointSize: CGFloat {
        let expanded: CGFloat = 34
        let collapsed: CGFloat = 22
        return expanded + (collapsed - expanded) * headerCollapseProgress
    }

    var body: some View {
        NavigationStack {
            GeometryReader { outerGeo in
                ZStack {
                    LeafIDTheme.deepForest.ignoresSafeArea()

                    VStack(spacing: 0) {
                        druidHeader
                            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                            .padding(.top, outerGeo.safeAreaInsets.top + LeafIDTheme.space8)
                            .padding(.bottom, LeafIDTheme.space8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(LeafIDTheme.surface)

                        ScrollView {
                            VStack(alignment: .leading, spacing: LeafIDTheme.space28) {
                                identityRow
                                rankBadgeCard
                                quotaCard
                                achievementsRow
                                supportCard
                                signOutFooter
                            }
                            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                            .padding(.top, LeafIDTheme.space12)
                            .padding(.bottom, LeafIDTheme.tabBarBottomReserve)
                            .background(
                                ScrollOffsetReader(offsetY: $rawScrollOffsetY)
                                    .frame(width: 0, height: 0)
                            )
                        }
                    }

                    if !authViewModel.isAuthenticated {
                        loginOverlay
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task { await viewModel.refresh(herbarium: herbarium) }
        .onReceive(NotificationCenter.default.publisher(for: .druidAuthDidChange)) { _ in
            Task { await viewModel.refresh(herbarium: herbarium) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .herbariumCollectionDidChange)) { _ in
            Task { await viewModel.refresh(herbarium: herbarium) }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var druidHeader: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            HStack(alignment: .center, spacing: LeafIDTheme.space16) {
                Text(String(localized: "Druid"))
                    .font(LeafIDFont.plusJakarta(size: druidTitlePointSize, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                Spacer(minLength: 0)
            }
            if headerCollapseProgress < 0.94 {
                Text(String(localized: "Your druid identity, progress, and unlocks."))
                    .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .opacity(Double(max(0, 1 - headerCollapseProgress / 0.82)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.2), value: headerCollapseProgress)
    }

    private var initialGlyph: String {
        let name = viewModel.profile?.displayName ?? "Druid"
        return String(name.prefix(1)).uppercased()
    }

    private var identityRow: some View {
        HStack(spacing: LeafIDTheme.space14) {
            ZStack {
                Circle()
                    .fill(LeafIDTheme.passportAvatarGradient)
                    .frame(width: 64, height: 64)
                Text(initialGlyph)
                    .font(LeafIDFont.plusJakarta(size: 26, weight: .bold))
                    .foregroundStyle(LeafIDTheme.chromeHighlight)
            }
            VStack(alignment: .leading, spacing: LeafIDTheme.space4) {
                Text(viewModel.realName)
                    .font(LeafIDFont.plusJakarta(size: 30, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(localized: "Botanical Explorer"))
                    .font(LeafIDFont.manrope(size: 16, weight: .medium))
                    .foregroundStyle(LeafIDTheme.slateMuted)
            }
            Spacer(minLength: 0)
        }
    }

    private var rankBadgeCard: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            Text(String(localized: "Current path"))
                .font(LeafIDFont.manrope(size: 12, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(LeafIDTheme.slateMuted)
                .textCase(.uppercase)
            HStack(spacing: LeafIDTheme.space8) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(LeafIDTheme.leafGreen)
                Text(viewModel.rankTitle)
                    .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Text(nextRankHint)
                .font(LeafIDFont.manrope(size: 13, weight: .medium))
                .foregroundStyle(LeafIDTheme.slateMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space14)
        .liquidGlass()
    }

    private var quotaCard: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            HStack(spacing: LeafIDTheme.space10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.leafGreen)
                Text(String(localized: "Scan energy"))
                    .font(LeafIDFont.plusJakarta(size: 16, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                Spacer(minLength: 0)
                if viewModel.isPremium {
                    Text(String(localized: "Unlimited"))
                        .font(LeafIDFont.manrope(size: 13, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.leafGreen)
                } else {
                    Text(viewModel.scanEnergyCounterLabel)
                        .font(LeafIDFont.manrope(size: 13, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                }
            }

            ProgressView(value: viewModel.energyProgress, total: 1)
                .tint(LeafIDTheme.leafGreen)
                .progressViewStyle(.linear)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)
                .clipShape(Capsule())

            Text(viewModel.isPremium ? String(localized: "Premium unlocked. You can scan without limits.") : String(localized: "You have 3 free scans. Unlock more to keep exploring."))
                .font(LeafIDFont.manrope(size: 12, weight: .medium))
                .foregroundStyle(LeafIDTheme.slateMuted)
            LeafPrimaryButton(title: String(localized: "Unlock more"), useSolidPrimaryFill: true, compact: true) {
                showPaywall = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space14)
        .liquidGlass()
    }

    private var achievementsRow: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            // Section label within a scrolling list, not a screen title — was set at the
            // same 30pt scale as a top-level heading despite the role being closer to a subtitle.
            Text(String(localized: "Achievements"))
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)

            let columns = [GridItem(.flexible(), spacing: LeafIDTheme.space12), GridItem(.flexible(), spacing: LeafIDTheme.space12)]
            LazyVGrid(columns: columns, spacing: LeafIDTheme.space12) {
                ForEach(druidAchievementTiles) { tile in
                    let unlocked = tile.isEarned
                    VStack(alignment: .leading, spacing: LeafIDTheme.space8) {
                        HStack {
                            Image(systemName: tile.definition.symbolName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(unlocked ? LeafIDTheme.primary : LeafIDTheme.slateMuted)
                            Spacer(minLength: 0)
                            Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(unlocked ? LeafIDTheme.primary : LeafIDTheme.slateMuted.opacity(0.8))
                        }
                        Text(tile.definition.title)
                            .font(LeafIDFont.plusJakarta(size: 18, weight: .bold))
                            .foregroundStyle(unlocked ? LeafIDTheme.onSurface : LeafIDTheme.slateMuted)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        Text(tile.definition.subtitle)
                            .font(LeafIDFont.manrope(size: 14, weight: .medium))
                            .foregroundStyle(LeafIDTheme.slateMuted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                    .padding(LeafIDTheme.space12)
                    .background(LeafIDTheme.surfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .opacity(unlocked ? 1 : 0.8)
                }
            }
        }
    }

    /// Real collection only — demo catalog does not unlock achievements.
    private var scansForAchievements: [Scan] {
        herbarium.isShowingPlaceholderCatalog ? [] : herbarium.scans
    }

    private var druidAchievementTiles: [AchievementTileState] {
        AchievementUnlockStore.tiles(scans: scansForAchievements)
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            Text(String(localized: "Support LeafID"))
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)
            Text(String(localized: "LeafID is an independent, non-profit project. If it helped you connect with nature, you can support maintenance with a small coffee."))
                .font(LeafIDFont.manrope(size: 14, weight: .medium))
                .foregroundStyle(LeafIDTheme.slateMuted)
                .lineSpacing(4)
            LeafPrimaryButton(title: String(localized: "Buy me a coffee"), useSolidPrimaryFill: true, compact: true) {
                showPaywall = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space14)
        .liquidGlass()
    }

    private var nextRankHint: String {
        switch viewModel.scansCount {
        case ..<6: return String(localized: "Complete 6 scans to unlock Forest Sprout.")
        case ..<16: return String(localized: "Complete 16 scans to unlock Oak Guardian.")
        case ..<50: return String(localized: "Complete 50 scans to unlock Archdruid.")
        default: return String(localized: "You reached the highest rank.")
        }
    }

    private var signOutFooter: some View {
        VStack(spacing: LeafIDTheme.space8) {
            LeafPrimaryButton(
                title: String(localized: "Log out"),
                leadingSystemImage: "rectangle.portrait.and.arrow.right",
                isEnabled: authViewModel.isAuthenticated,
                useSolidPrimaryFill: true
            ) {
                authViewModel.signOut()
            }
            if let privacyPolicyURL {
                Link(String(localized: "Privacy Policy"), destination: privacyPolicyURL)
                    .font(LeafIDFont.manrope(size: 13, weight: .medium))
                    .foregroundStyle(LeafIDTheme.slateMuted)
                    .padding(.top, LeafIDTheme.space4)
            }
        }
        .padding(.top, LeafIDTheme.space10)
    }

    private var privacyPolicyURL: URL? {
        URL(string: "https://marianaminsp.github.io/leafid-native/docs/PRIVACY_POLICY.html")
    }

    private var loginOverlay: some View {
        ZStack {
            LeafIDTheme.shadowBase.opacity(0.55).ignoresSafeArea()
            VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                Text(String(localized: "Welcome back"))
                    .font(LeafIDFont.plusJakarta(size: 24, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                Text(String(localized: "Sign in with Google to unlock your Druid passport and sync your progress."))
                    .font(LeafIDFont.manrope(size: 15, weight: .medium))
                    .foregroundStyle(LeafIDTheme.slateMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    guard let url = authViewModel.googleOAuthURL() else {
                        authViewModel.lastError =
                            "Supabase is not configured. Add SUPABASE_URL (quoted) and SUPABASE_ANON_KEY in Secrets.local.xcconfig."
                        return
                    }
                    authViewModel.lastError = nil
                    openURL(url)
                } label: {
                    HStack(spacing: LeafIDTheme.space10) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .semibold))
                        Text(String(localized: "Continue with Google"))
                            .font(LeafIDFont.plusJakarta(size: 16, weight: .bold))
                    }
                    .foregroundStyle(LeafIDTheme.onPrimary)
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
