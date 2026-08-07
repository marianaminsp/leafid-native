//
//  DruidNeoBrutalistView.swift
//  LeafID-native
//
//  Sixth and final redesign screen — a 1:1 SwiftUI build of stitch_botanical_explorer/the_druid/code.html
//  (the Druid tab / profile & gamification screen). Avatar and badge art are the mockup's own
//  placeholders, not real user photos or final badge illustrations.
//

import SwiftUI

struct DruidNeoBrutalistView: View {
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @State private var missingFeature: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                    statsRow
                    relicsSection
                        .padding(NeoBrutalistSpacing.md)
                }
            }

            NeoBrutalistTabBar(activeTab: .druid, onSelect: onSelectTab)
        }
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: NeoBrutalistSpacing.sm) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(NeoBrutalistColor.onSurface)
            Text("DRUID")
                .font(NeoBrutalistFont.headlineMd())
                .foregroundStyle(NeoBrutalistColor.onSurface)

            Spacer()

            Button(action: { missingFeature = "Account Settings" }) {
                ZStack {
                    Circle().fill(NeoBrutalistColor.primary)
                    Image(systemName: "person.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(NeoBrutalistColor.onPrimary)
                }
                .frame(width: 36, height: 36)
                .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NeoBrutalistSpacing.md)
        .padding(.vertical, NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.surface.opacity(0.94))
    }

    // MARK: - Profile header

    private var profileHeader: some View {
        VStack(spacing: NeoBrutalistSpacing.sm) {
            ZStack(alignment: .bottomTrailing) {
                Image("DruidAvatarPlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 128, height: 128)
                    .clipped()
                    .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                    .neoBrutalistHardShadow(offset: 8, color: NeoBrutalistColor.primary)

                Text("LVL 24")
                    .font(.custom("SpaceMono-Bold", size: 12))
                    .foregroundStyle(NeoBrutalistColor.onSecondary)
                    .padding(.horizontal, NeoBrutalistSpacing.sm)
                    .padding(.vertical, NeoBrutalistSpacing.xs)
                    .background(NeoBrutalistColor.secondary)
                    .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                    .offset(x: 12, y: 12)
            }
            .padding(.bottom, NeoBrutalistSpacing.sm)

            Text("ELDER DRUID")
                .font(NeoBrutalistFont.headlineLgMobile())
                .foregroundStyle(NeoBrutalistColor.onSurface)
            Text("@UrbanForager_99")
                .font(.custom("SpaceMono-Bold", size: 12))
                .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)

            xpBar
                .padding(.top, NeoBrutalistSpacing.md)
        }
        .padding(.horizontal, NeoBrutalistSpacing.md)
        .padding(.top, NeoBrutalistSpacing.lg)
        .padding(.bottom, NeoBrutalistSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(NeoBrutalistColor.surfaceContainer)
        .overlay(alignment: .bottom) {
            Rectangle().fill(NeoBrutalistColor.ink).frame(height: NeoBrutalistStroke.heavy)
        }
    }

    private var xpBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                NeoBrutalistColor.surface
                Rectangle()
                    .fill(NeoBrutalistColor.primaryContainer)
                    .frame(width: geo.size.width * 0.82)
                Text("8,240 / 10,000 XP")
                    .font(.custom("SpaceMono-Bold", size: 11))
                    .kerning(1)
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 24)
        .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: NeoBrutalistSpacing.md) {
            statTile(icon: "sparkles", iconColor: NeoBrutalistColor.tertiary, value: "142", label: "Discoveries\nRooted")
            statTile(icon: "leaf.fill", iconColor: NeoBrutalistColor.secondary, value: "38", label: "Ancient Seeds\nCollected")
        }
        .padding(NeoBrutalistSpacing.md)
        .background(NeoBrutalistColor.primaryContainer)
        .overlay(alignment: .bottom) {
            Rectangle().fill(NeoBrutalistColor.ink).frame(height: NeoBrutalistStroke.heavy)
        }
    }

    private func statTile(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: NeoBrutalistSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(iconColor)
            Text(value)
                .font(NeoBrutalistFont.displayLg())
                .foregroundStyle(NeoBrutalistColor.onSurface)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label)
                .font(.custom("SpaceMono-Bold", size: 10))
                .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                .lineLimit(2)
        }
        .padding(NeoBrutalistSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NeoBrutalistColor.surface)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
    }

    // MARK: - Relics & badges

    private var relicsSection: some View {
        VStack(alignment: .leading, spacing: NeoBrutalistSpacing.md) {
            HStack {
                Text("RELICS & BADGES")
                    .font(NeoBrutalistFont.headlineMd())
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                Spacer()
                Button(action: { missingFeature = "All Relics & Badges" }) {
                    Text("VIEW ALL")
                        .font(.custom("SpaceMono-Bold", size: 11))
                        .foregroundStyle(NeoBrutalistColor.onSurface)
                        .padding(.horizontal, NeoBrutalistSpacing.sm)
                        .padding(.vertical, NeoBrutalistSpacing.xs)
                        .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: NeoBrutalistSpacing.md), GridItem(.flexible())], spacing: NeoBrutalistSpacing.md) {
                badge(image: "NightshadeBadge", title: "NIGHTSHADE NAV", subtitle: "FOUND 10 TOXIC FLORA", shadowColor: NeoBrutalistColor.primary)
                badge(image: "ConcreteJungleBadge", title: "CONCRETE JUNGLE", subtitle: "LOGGED 50 CITY WEEDS", shadowColor: NeoBrutalistColor.secondary)
                lockedBadge(title: "MYCOLOGIST", subtitle: "ID 20 FUNGI (14/20)")
                lockedBadge(title: "SUN WALKER", subtitle: "LOG 5 DESERT PLANTS")
            }
        }
    }

    private func badge(image: String, title: String, subtitle: String, shadowColor: Color) -> some View {
        VStack(spacing: NeoBrutalistSpacing.sm) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
            Text(title)
                .font(NeoBrutalistFont.bodyMedium(size: 14))
                .foregroundStyle(NeoBrutalistColor.onSurface)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.custom("SpaceMono-Bold", size: 9))
                .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(NeoBrutalistSpacing.md)
        .frame(maxWidth: .infinity)
        .background(NeoBrutalistColor.surfaceContainerHighest)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 6, shadowColor: shadowColor)
        .contentShape(Rectangle())
        .onTapGesture { missingFeature = "Badge Detail (\(title))" }
    }

    private func lockedBadge(title: String, subtitle: String) -> some View {
        VStack(spacing: NeoBrutalistSpacing.sm) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(NeoBrutalistColor.outline)
                .frame(width: 56, height: 56)
            Text(title)
                .font(NeoBrutalistFont.bodyMedium(size: 14))
                .foregroundStyle(NeoBrutalistColor.outline)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.custom("SpaceMono-Bold", size: 9))
                .foregroundStyle(NeoBrutalistColor.outline)
                .multilineTextAlignment(.center)
        }
        .padding(NeoBrutalistSpacing.md)
        .frame(maxWidth: .infinity)
        .background(NeoBrutalistColor.surface)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4, shadowColor: NeoBrutalistColor.outlineVariant)
        .contentShape(Rectangle())
        .onTapGesture { missingFeature = "Locked Badge Detail (\(title))" }
    }
}

struct DruidNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        DruidNeoBrutalistView()
    }
}
