//
//  ProfileView.swift
//  LeafID-native
//
//  Layout `docs/ui-screens/Profile.png` — scroll-collapsing header matches Herbarium behavior (PDR / HerbariumView).
//

import SwiftUI

private struct ProfileHeaderMinYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ProfileView: View {
    @EnvironmentObject private var herbarium: HerbariumViewModel
    @StateObject private var profileModel = ProfileViewModel()

    @State private var headerMinY: CGFloat = 0
    @State private var showSettings = false
    @State private var showFoundryPasswordGate = false
    @State private var showFoundryGallery = false

    private var headerCollapseProgress: CGFloat {
        let y = headerMinY
        let threshold: CGFloat = 96
        if y >= 0 { return 0 }
        return min(1, -y / threshold)
    }

    private var profileTitlePointSize: CGFloat {
        let expanded: CGFloat = 34
        let collapsed: CGFloat = 22
        return expanded + (collapsed - expanded) * headerCollapseProgress
    }

    private var plants: Int { profileModel.plantsCount(from: herbarium) }
    private var species: Int { profileModel.distinctSpeciesCount(from: herbarium) }
    private var scans: Int { profileModel.scansCount(from: herbarium) }
    private var collectionFeed: [ProfileFeedItem] { profileModel.collectionFeed(from: herbarium) }
    private var scansForAchievements: [Scan] {
        herbarium.isShowingPlaceholderCatalog ? [] : herbarium.scans
    }

    private var achievementTiles: [AchievementTileState] { AchievementUnlockStore.tiles(scans: scansForAchievements) }
    private var localSnapshot: ProfileStatsSnapshot { ProfileStatsLocalStore.snapshot(from: herbarium.scans) }

    var body: some View {
        GeometryReader { outerGeo in
            ZStack {
                LeafIDTheme.surface.ignoresSafeArea()

                VStack(spacing: 0) {
                    profileScrollHeader
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                        .padding(.top, outerGeo.safeAreaInsets.top + LeafIDTheme.space8)
                        .padding(.bottom, LeafIDTheme.space4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LeafIDTheme.surface)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: LeafIDTheme.space20) {
                            Color.clear
                                .frame(height: 1)
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: ProfileHeaderMinYKey.self,
                                            value: proxy.frame(in: .named("profileScroll")).minY
                                        )
                                    }
                                )

                            profileStatsCard

                            profileBentoStatsSection

                            achievementsSection

                            recentDiscoveriesSection

                            #if DEBUG
                            profileFoundryFooter
                            #endif
                        }
                        .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                        .padding(.top, LeafIDTheme.space8)
                        .padding(.bottom, LeafIDTheme.space28)
                    }
                    .coordinateSpace(name: "profileScroll")
                    .onPreferenceChange(ProfileHeaderMinYKey.self) { headerMinY = $0 }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            profileSettingsSheet
        }
        #if DEBUG
        .sheet(isPresented: $showFoundryPasswordGate) {
            FoundryPasswordGateSheet(
                isPresented: $showFoundryPasswordGate,
                showGallery: $showFoundryGallery
            )
        }
        .fullScreenCover(isPresented: $showFoundryGallery) {
            DesignSystemGalleryView(dismiss: { showFoundryGallery = false })
        }
        #endif
    }

    private var profileScrollHeader: some View {
        HStack(alignment: .top, spacing: LeafIDTheme.space16) {
            Text("Druid")
                .font(LeafIDFont.plusJakarta(size: profileTitlePointSize, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showSettings = true
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
            .accessibilityLabel("Settings")
        }
        .animation(.easeOut(duration: 0.2), value: headerCollapseProgress)
    }

    private var profileStatsCard: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space20) {
            HStack(alignment: .center, spacing: LeafIDTheme.space20) {
                profileAvatar
                VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                    Text(profileModel.displayName)
                        .font(LeafIDFont.plusJakarta(size: 22, weight: .bold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                    Text(profileModel.roleTitle)
                        .font(LeafIDFont.manrope(size: 15, weight: .medium))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                profileStatColumn(value: plants, label: "Plants")
                profileStatDivider
                profileStatColumn(value: species, label: "Species")
                profileStatDivider
                profileStatColumn(value: scans, label: "Scans")
            }
        }
        .padding(LeafIDTheme.space24)
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.1), lineWidth: 1)
        }
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LeafIDTheme.primary.opacity(0.35),
                            LeafIDTheme.surfaceContainerLow,
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 56
                    )
                )
                .frame(width: 88, height: 88)
            Image(systemName: "leaf.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(LeafIDTheme.primary)
                .symbolRenderingMode(.hierarchical)
        }
        .overlay {
            Circle()
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.2), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Profile photo")
    }

    private func profileStatColumn(value: Int, label: String) -> some View {
        VStack(spacing: LeafIDTheme.space6) {
            Text(ProfileViewModel.formatCount(value))
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.primary)
            Text(label)
                .font(LeafIDFont.manrope(size: 12, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
    }

    private var profileStatDivider: some View {
        Rectangle()
            .fill(LeafIDTheme.outlineVariant.opacity(0.2))
            .frame(width: 1, height: 40)
    }

    private var achievementGridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: LeafIDTheme.space12), GridItem(.flexible(), spacing: LeafIDTheme.space12)]
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space14) {
            Text("Achievements")
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)

            LazyVGrid(columns: achievementGridColumns, spacing: LeafIDTheme.space12) {
                ForEach(achievementTiles) { tile in
                    DruidAchievementGridTile(tile: tile)
                }
            }
        }
    }

    private var recentDiscoveriesSection: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space14) {
            Text("Recent Discoveries")
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)

            if collectionFeed.isEmpty {
                Text("Identify a plant and save it to your Herbarium — it will show up here.")
                    .font(LeafIDFont.manrope(size: 14, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .padding(LeafIDTheme.space20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LeafIDTheme.surfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            } else {
                ForEach(collectionFeed) { item in
                    ProfileDiscoveryRow(item: item)
                }
            }
        }
    }

    #if DEBUG
    private var profileFoundryFooter: some View {
        Button {
            showFoundryPasswordGate = true
        } label: {
            HStack(alignment: .center, spacing: LeafIDTheme.space16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LeafIDTheme.surfaceContainerHigh)
                        .frame(width: 48, height: 48)
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.primary)
                }
                VStack(alignment: .leading, spacing: LeafIDTheme.space4) {
                    Text("Foundry")
                        .font(LeafIDFont.plusJakarta(size: 17, weight: .semibold))
                        .foregroundStyle(LeafIDTheme.onSurface)
                    Text("Design system gallery")
                        .font(LeafIDFont.manrope(size: 13, weight: .medium))
                        .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.outlineVariant.opacity(0.45))
            }
            .padding(LeafIDTheme.space16)
            .background(LeafIDTheme.surfaceContainerHigh)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Design System Foundry")
    }
    #endif

    private var profileBentoStatsSection: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space14) {
            Text("Field Intelligence")
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)

            let columns = [GridItem(.flexible(), spacing: LeafIDTheme.space12), GridItem(.flexible(), spacing: LeafIDTheme.space12)]
            LazyVGrid(columns: columns, spacing: LeafIDTheme.space12) {
                bentoTile(title: "Unique Families", value: "\(localSnapshot.uniqueFamilies)")
                bentoTile(title: "Unlocked Countries", value: "\(localSnapshot.unlockedCountries.count)")
                bentoDominantColorTile
                bentoTile(title: "Discovery Streak", value: "\(localSnapshot.discoveryStreakDays) days")
            }
            if let first = localSnapshot.firstDiscoveryDate {
                Text("First discovery: \(profileModel.mediumDate(first))")
                    .font(LeafIDFont.manrope(size: 13, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            }
        }
    }

    private func bentoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
            Text(title)
                .font(LeafIDFont.manrope(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .textCase(.uppercase)
            Text(value)
                .font(LeafIDFont.plusJakarta(size: 18, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(LeafIDTheme.space14)
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.12), lineWidth: 1)
        }
    }

    private var bentoDominantColorTile: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
            Text("Dominant Color")
                .font(LeafIDFont.manrope(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                .textCase(.uppercase)
            HStack(spacing: LeafIDTheme.space8) {
                Circle()
                    .fill(profileModel.colorFromHex(localSnapshot.dominantColorHex))
                    .frame(width: 22, height: 22)
                    .overlay {
                        Circle().strokeBorder(LeafIDTheme.outlineVariant.opacity(0.28), lineWidth: 1)
                    }
                Text(localSnapshot.dominantColorHex)
                    .font(LeafIDFont.plusJakarta(size: 16, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(LeafIDTheme.space14)
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.12), lineWidth: 1)
        }
    }

    private var profileSettingsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: LeafIDTheme.space16) {
                Text("Account and notifications will connect to Supabase when sign-in is enabled in this build.")
                    .font(LeafIDFont.manrope(size: 15, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                Spacer(minLength: 0)
            }
            .padding(LeafIDTheme.space24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(LeafIDTheme.surface.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ModalCloseButton {
                        showSettings = false
                        ToastCenter.shared.show(
                            String(localized: "Profile settings updated."),
                            kind: .success
                        )
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Achievement tile (matches Field Intelligence / bento chrome)

private struct DruidAchievementGridTile: View {
    let tile: AchievementTileState

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: LeafIDTheme.space6) {
                Image(systemName: tile.definition.symbolName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tile.isEarned ? LeafIDTheme.primary : LeafIDTheme.onSurfaceVariant.opacity(0.55))
                    .symbolRenderingMode(.hierarchical)
                Text(tile.definition.title)
                    .font(LeafIDFont.plusJakarta(size: 16, weight: .bold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                    .opacity(tile.isEarned ? 1 : 0.55)
                Text(tile.definition.subtitle)
                    .font(LeafIDFont.manrope(size: 12, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .lineLimit(2)
                    .opacity(tile.isEarned ? 1 : 0.65)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)

            if tile.isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.primary)
                    .padding(LeafIDTheme.space4)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant.opacity(0.5))
                    .padding(LeafIDTheme.space6)
            }
        }
        .padding(LeafIDTheme.space14)
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.resultsSheetTop, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.12), lineWidth: 1)
        }
        .opacity(tile.isEarned ? 1 : 0.88)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tile.definition.title). \(tile.isEarned ? "Unlocked" : "Locked"). \(tile.definition.subtitle)")
    }
}

// MARK: - Foundry (Druid screen)

private enum FoundryGate {
    static let password = "Test"
}

private struct FoundryPasswordGateSheet: View {
    @Binding var isPresented: Bool
    @Binding var showGallery: Bool
    @State private var passwordEntry = ""
    @State private var gateError = false
    @FocusState private var passwordFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: LeafIDTheme.space20) {
                Text("Design System Foundry")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(LeafIDTheme.onSurface)

                SecureField("Password", text: $passwordEntry)
                    .textContentType(.password)
                    .focused($passwordFocused)
                    .padding(LeafIDTheme.space16)
                    .background(LeafIDTheme.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: LeafIDTheme.space12, style: .continuous)
                            .strokeBorder(
                                gateError ? LeafIDTheme.primary.opacity(0.45) : LeafIDTheme.outlineVariant.opacity(0.15),
                                lineWidth: 1
                            )
                    }

                if gateError {
                    Text("Incorrect password")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LeafIDTheme.primary.opacity(0.9))
                }

                Button("Unlock Foundry") {
                    attemptUnlock()
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
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
                    ModalCloseButton { isPresented = false }
                }
            }
            .onAppear { passwordFocused = true }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            passwordEntry = ""
            gateError = false
        }
    }

    private func attemptUnlock() {
        if passwordEntry == FoundryGate.password {
            gateError = false
            isPresented = false
            passwordEntry = ""
            showGallery = true
        } else {
            gateError = true
        }
    }
}

// MARK: - Discovery row

private struct ProfileDiscoveryRow: View {
    let item: ProfileFeedItem

    private var leadingSymbol: String {
        if item.isAchievement { return "trophy.fill" }
        return "leaf.fill"
    }

    var body: some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LeafIDTheme.primary.opacity(0.22))
                    .frame(width: 48, height: 48)
                Image(systemName: leadingSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.primary)
            }

            VStack(alignment: .leading, spacing: LeafIDTheme.space4) {
                Text(item.title)
                    .font(LeafIDFont.plusJakarta(size: 17, weight: .semibold))
                    .foregroundStyle(LeafIDTheme.onSurface)
                Text(item.subtitle)
                    .font(LeafIDFont.manrope(size: 13, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
            }
            Spacer(minLength: 0)
        }
        .padding(LeafIDTheme.space16)
        .background(LeafIDTheme.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.08), lineWidth: 1)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(HerbariumViewModel())
    }
}
