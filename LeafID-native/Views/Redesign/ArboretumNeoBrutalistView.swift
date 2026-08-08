//
//  ArboretumNeoBrutalistView.swift
//  LeafID-native
//
//  Fourth redesign screen — a 1:1 SwiftUI build of stitch_botanical_explorer/the_arboretum/code.html.
//  Map and log-thumbnail images are the mockup's own placeholders, not live MapKit / real specimen
//  photos — this screen stays a static visual until the real Arboretum map (ADR-0002) is re-enabled.
//
//  The map card carries an explicit "Map: Growing" WIP sticker (desaturated/scrimmed map, centered
//  hard-shadow card) per the "Leaf ID — Arboretum (WIP)" design exploration, so it reads as
//  intentionally unfinished rather than a broken live map. The individual specimen pins were dropped
//  for the same reason — a "tap this pin" affordance next to a sticker that says the map isn't
//  interactive yet would send two contradicting messages.
//

import SwiftUI

struct ArboretumNeoBrutalistView: View {
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @State private var missingFeature: String?
    @State private var selectedZone = "ALL ZONES"

    var body: some View {
        VStack(spacing: 0) {
            NeoBrutalistAppHeader(onAvatarTap: { onSelectTab(.druid) })

            ScrollView {
                VStack(alignment: .leading, spacing: NeoBrutalistSpacing.lg) {
                    headerCard
                    mapCard
                    recentLogsSection
                    exploreNowButton
                }
                .padding(.horizontal, NeoBrutalistSpacing.md)
                .padding(.top, NeoBrutalistSpacing.md)
                .padding(.bottom, NeoBrutalistSpacing.lg)
            }

            NeoBrutalistTabBar(activeTab: .map, onSelect: onSelectTab)
        }
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Header card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: NeoBrutalistSpacing.sm) {
            VStack(alignment: .leading, spacing: 0) {
                Text("EXPLORE THE")
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                Text("ARBORETUM")
                    .foregroundStyle(NeoBrutalistColor.primary)
            }
            .font(NeoBrutalistFont.headlineLgMobile())

            HStack(alignment: .top, spacing: NeoBrutalistSpacing.md) {
                Rectangle()
                    .fill(NeoBrutalistColor.primary)
                    .frame(width: 4)
                Text("See where your botanical discoveries took root on our interactive map.")
                    .font(NeoBrutalistFont.bodyMedium(size: 16))
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
            }
        }
        .padding(NeoBrutalistSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NeoBrutalistColor.surfaceContainer)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 6)
    }

    // MARK: - Map

    private var mapCard: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                Image("ArboretumMapPlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .saturation(0.7)
                    .brightness(-0.08)
            }
            .frame(height: 320)

            RadialGradient(
                colors: [NeoBrutalistColor.ink.opacity(0.14), NeoBrutalistColor.ink.opacity(0.34)],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 20,
                endRadius: 280
            )
            .allowsHitTesting(false)

            wipSticker

            HStack(spacing: NeoBrutalistSpacing.sm) {
                zoneChip("ALL ZONES")
                zoneChip("RARE FINDS")
                zoneChip("RECENT")
            }
            .padding(NeoBrutalistSpacing.sm)
        }
        .frame(height: 320)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 8)
    }

    /// "Map: Growing" — the honest-WIP treatment: a tilted, hard-shadow sticker centered over the
    /// desaturated/scrimmed map, naming the specific missing interaction rather than a bare
    /// "coming soon."
    private var wipSticker: some View {
        VStack(spacing: NeoBrutalistSpacing.xs) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(NeoBrutalistColor.onSurface)
            Text("MAP: GROWING")
                .font(NeoBrutalistFont.headlineMd())
                .foregroundStyle(NeoBrutalistColor.onSurface)
            Text("DRAG & PAN COMING SOON")
                .font(.custom("SpaceMono-Bold", size: 10.5))
                .kerning(1)
                .foregroundStyle(NeoBrutalistColor.onTertiaryContainer)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 26)
        .padding(.vertical, 20)
        .background(NeoBrutalistColor.tertiaryContainer)
        .neoBrutalistSurface(borderWidth: 4, shadowOffset: 8)
        .rotationEffect(.degrees(-3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func zoneChip(_ title: String) -> some View {
        let filled = selectedZone == title
        return Button(action: { selectedZone = title }) {
            Text(title)
                .font(.custom("SpaceMono-Bold", size: 11))
                .kerning(1)
                .foregroundStyle(filled ? NeoBrutalistColor.onPrimary : NeoBrutalistColor.onSurface)
                .padding(.horizontal, NeoBrutalistSpacing.sm)
                .padding(.vertical, NeoBrutalistSpacing.xs)
                .background(filled ? NeoBrutalistColor.primary : NeoBrutalistColor.surface)
                .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 4)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 4))
    }

    // MARK: - Recent logs

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: NeoBrutalistSpacing.md) {
            HStack {
                Text("RECENT LOGS")
                    .font(NeoBrutalistFont.headlineMd())
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                Spacer()
                Text("3 NEW")
                    .font(.custom("SpaceMono-Bold", size: 11))
                    .foregroundStyle(NeoBrutalistColor.secondary)
                    .padding(.horizontal, NeoBrutalistSpacing.xs)
                    .padding(.vertical, 2)
                    .overlay(Rectangle().strokeBorder(NeoBrutalistColor.secondary, lineWidth: NeoBrutalistStroke.default))
            }
            .padding(.bottom, NeoBrutalistSpacing.xs)
            .overlay(alignment: .bottom) {
                Rectangle().fill(NeoBrutalistColor.ink).frame(height: NeoBrutalistStroke.heavy)
            }

            logRow(image: "PinstripeCalatheaThumb", name: "PINSTRIPE CALATHEA", latin: "Calathea ornata", tag: "URBAN", confirmed: true)
            logRow(image: "AfricanMaskThumb", name: "AFRICAN MASK", latin: "Alocasia amazonica", tag: "WILD", confirmed: false)
        }
    }

    private func logRow(image: String, name: String, latin: String, tag: String, confirmed: Bool) -> some View {
        HStack(spacing: NeoBrutalistSpacing.md) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipped()
                .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(NeoBrutalistFont.bodyMedium(size: 16))
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                Text(latin)
                    .font(.custom("SpaceMono-Bold", size: 10))
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: NeoBrutalistSpacing.xs) {
                Text(tag)
                    .font(.custom("SpaceMono-Bold", size: 9))
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                    .padding(.horizontal, 4)
                    .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: 1))
                Image(systemName: confirmed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(confirmed ? NeoBrutalistColor.primaryContainer : NeoBrutalistColor.outline)
            }
        }
        .padding(NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.surfaceContainer)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 4)
        .contentShape(Rectangle())
        .onTapGesture { missingFeature = "Botanical Card (\(name))" }
    }

    // MARK: - CTA

    private var exploreNowButton: some View {
        Button(action: { missingFeature = "Explore Now" }) {
            HStack(spacing: NeoBrutalistSpacing.sm) {
                Text("Explore Now")
                Image(systemName: "arrow.right")
            }
            .font(NeoBrutalistFont.headlineMd())
            .foregroundStyle(NeoBrutalistColor.onTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(NeoBrutalistColor.tertiary)
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 6)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 6))
    }
}

struct ArboretumNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        ArboretumNeoBrutalistView()
    }
}
