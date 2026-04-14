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
    private var feed: [ProfileFeedItem] { profileModel.profileFeed(from: herbarium) }

    var body: some View {
        ZStack {
            LeafIDTheme.surface.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: LeafIDTheme.space20) {
                    profileScrollHeader
                        .padding(.bottom, LeafIDTheme.space4)

                    profileStatsCard

                    recentDiscoveriesSection
                }
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                .padding(.top, LeafIDTheme.space8)
                .padding(.bottom, LeafIDTheme.space28)
            }
            .coordinateSpace(name: "profileScroll")
            .onPreferenceChange(ProfileHeaderMinYKey.self) { headerMinY = $0 }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            profileSettingsSheet
        }
    }

    private var profileScrollHeader: some View {
        HStack(alignment: .top, spacing: LeafIDTheme.space16) {
            Text("Profile")
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
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ProfileHeaderMinYKey.self,
                    value: geo.frame(in: .named("profileScroll")).minY
                )
            }
        )
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

    private var recentDiscoveriesSection: some View {
        VStack(alignment: .leading, spacing: LeafIDTheme.space14) {
            Text("Recent Discoveries")
                .font(LeafIDFont.plusJakarta(size: 20, weight: .bold))
                .foregroundStyle(LeafIDTheme.onSurface)

            if feed.isEmpty {
                Text("Identify a plant and save it to your Herbarium — it will show up here.")
                    .font(LeafIDFont.manrope(size: 14, weight: .medium))
                    .foregroundStyle(LeafIDTheme.onSurfaceVariant)
                    .padding(LeafIDTheme.space20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LeafIDTheme.surfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            } else {
                ForEach(feed) { item in
                    ProfileDiscoveryRow(item: item)
                }
            }
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showSettings = false }
                        .foregroundStyle(LeafIDTheme.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Discovery row

private struct ProfileDiscoveryRow: View {
    let item: ProfileFeedItem

    var body: some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LeafIDTheme.primary.opacity(0.22))
                    .frame(width: 48, height: 48)
                Image(systemName: "leaf.fill")
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
