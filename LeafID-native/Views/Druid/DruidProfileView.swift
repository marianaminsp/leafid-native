//
//  DruidProfileView.swift
//  LeafID-native
//
//  The Druid — passport-style identity & progression (PDR §2 / protocol Tab 4).
//

import SwiftUI

private struct DruidHeaderMinYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct DruidProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var herbarium: HerbariumViewModel
    @StateObject private var viewModel = DruidProfileViewModel()
    @State private var showPaywall = false
    @State private var showFoundryPasswordGate = false
    @State private var showFoundryGallery = false
    @State private var foundryPasswordEntry = ""
    @State private var foundryPasswordError = false
    @State private var headerMinY: CGFloat = 0
    @Environment(\.openURL) private var openURL

    private var headerCollapseProgress: CGFloat {
        let y = headerMinY
        let threshold: CGFloat = 96
        if y >= 0 { return 0 }
        return min(1, -y / threshold)
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
                                Color.clear
                                    .frame(height: 1)
                                    .background(
                                        GeometryReader { proxy in
                                            Color.clear.preference(
                                                key: DruidHeaderMinYKey.self,
                                                value: proxy.frame(in: .named("druidScroll")).minY
                                            )
                                        }
                                    )

                                identityRow
                                rankBadgeCard
                                quotaCard
                                achievementsRow
                                supportCard
                                #if DEBUG
                                foundryAccessCard
                                #endif
                                signOutFooter
                            }
                            .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                            .padding(.top, LeafIDTheme.space12)
                            .padding(.bottom, 140)
                        }
                        .coordinateSpace(name: "druidScroll")
                        .onPreferenceChange(DruidHeaderMinYKey.self) { headerMinY = $0 }
                    }

                    if !viewModel.isLoggedIn {
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
        #if DEBUG
        .sheet(isPresented: $showFoundryPasswordGate) {
            foundryPasswordSheet
        }
        .fullScreenCover(isPresented: $showFoundryGallery) {
            DesignSystemGalleryView(dismiss: { showFoundryGallery = false })
        }
        #endif
    }

    private var druidHeader: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            HStack(alignment: .center, spacing: LeafIDTheme.space16) {
                Text(String(localized: "Druid"))
                    .font(LeafIDFont.plusJakarta(size: druidTitlePointSize, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                Spacer(minLength: 0)
                #if DEBUG
                Button {
                    showFoundryPasswordGate = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                        .background(LeafIDTheme.surfaceContainerHigh.opacity(0.85))
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.12), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                #endif
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
        .padding(LeafIDTheme.space20)
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
            LeafPrimaryButton(title: String(localized: "Unlock more"), useSolidPrimaryFill: true) {
                showPaywall = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space20)
        .liquidGlass()
    }

    private var achievementsRow: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            Text(String(localized: "Achievements"))
                .font(LeafIDFont.plusJakarta(size: 30, weight: .bold))
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
                    .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
                    .padding(LeafIDTheme.space16)
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

    #if DEBUG
    private var foundryAccessCard: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space14) {
            Text(String(localized: "Foundry"))
                .font(LeafIDFont.plusJakarta(size: 22, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)
            Text(String(localized: "Design system gallery and internal tools."))
                .font(LeafIDFont.manrope(size: 14, weight: .medium))
                .foregroundStyle(LeafIDTheme.slateMuted)
            LeafPrimaryButton(title: String(localized: "Open Foundry"), useSolidPrimaryFill: true) {
                showFoundryPasswordGate = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space20)
        .liquidGlass()
    }
    #endif

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space12) {
            Text(String(localized: "Support LeafID"))
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)
            Text(String(localized: "LeafID is an independent, non-profit project. If it helped you connect with nature, you can support maintenance with a small coffee."))
                .font(LeafIDFont.manrope(size: 14, weight: .medium))
                .foregroundStyle(LeafIDTheme.slateMuted)
                .lineSpacing(4)
            LeafPrimaryButton(title: String(localized: "Buy me a coffee"), useSolidPrimaryFill: true) {
                showPaywall = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LeafIDTheme.space20)
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
        }
        .padding(.top, LeafIDTheme.space10)
    }

    #if DEBUG
    private var foundryPasswordSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                Text("Design System Foundry")
                    .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)

                SecureField(String(localized: "Password"), text: $foundryPasswordEntry)
                    .textContentType(.password)
                    .padding(LeafIDTheme.space16)
                    .background(LeafIDTheme.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous)
                            .strokeBorder(
                                foundryPasswordError ? LeafIDTheme.primary.opacity(0.45) : LeafIDTheme.outlineVariant.opacity(0.15),
                                lineWidth: 1
                            )
                    }

                if foundryPasswordError {
                    Text("Incorrect password")
                        .font(LeafIDFont.manrope(size: 13, weight: .medium))
                        .foregroundStyle(LeafIDTheme.errorForeground)
                }

                Button(String(localized: "Unlock Foundry")) {
                    if foundryPasswordEntry == "Test" {
                        foundryPasswordError = false
                        showFoundryPasswordGate = false
                        foundryPasswordEntry = ""
                        showFoundryGallery = true
                    } else {
                        foundryPasswordError = true
                    }
                }
                .font(LeafIDFont.manrope(size: 17, weight: .semibold))
                .foregroundStyle(LeafIDTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LeafIDTheme.space14)
                .background(LeafIDTheme.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(LeafIDTheme.space24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(LeafIDTheme.surface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ModalCloseButton {
                        showFoundryPasswordGate = false
                        foundryPasswordEntry = ""
                        foundryPasswordError = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    #endif

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
