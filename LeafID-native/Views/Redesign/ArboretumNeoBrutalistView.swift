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
            VStack(alignment: .leading, spacing: NeoBrutalistSpacing.md) {
                headerCard
                mapCard
            }
            .padding(.horizontal, NeoBrutalistSpacing.md)
            .padding(.top, NeoBrutalistSpacing.md)
            .padding(.bottom, NeoBrutalistSpacing.md)

            NeoBrutalistTabBar(activeTab: .map, onSelect: onSelectTab)
        }
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Header

    /// Plain text on the screen background, matching the canonical "Leaf ID — Arboretum (WIP)"
    /// artifact (`.headline` has no card wrapper — the same no-card treatment as Identify's own
    /// headline) — not a bordered/shadowed card like the rest of this screen's surfaces.
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("EXPLORE THE")
                .font(NeoBrutalistFont.headlineLgMobile())
                .foregroundStyle(NeoBrutalistColor.onSurface)
            Text("ARBORETUM")
                .font(NeoBrutalistFont.headlineLgMobile())
                .foregroundStyle(NeoBrutalistColor.primary)

            Text("See where your botanical discoveries took root — drag & pan are on the way.")
                .font(NeoBrutalistFont.bodyMedium(size: 16))
                .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                .padding(.leading, NeoBrutalistSpacing.md)
                .padding(.top, NeoBrutalistSpacing.sm)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(NeoBrutalistColor.ink)
                        .frame(width: 4)
                        .padding(.top, NeoBrutalistSpacing.sm)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Map

    /// The one flexible element absorbing leftover space — this screen fits one viewport with no
    /// scroll, same as Identify's hero card, per the canonical artifact ("recent logs" was
    /// deliberately dropped from this screen to make that hold: "a map is one continuous canvas
    /// the same way the homepage hero is").
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
            .padding(.trailing, 52)
            .padding(NeoBrutalistSpacing.sm)

            recenterButton
                .padding(NeoBrutalistSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 8)
    }

    private var recenterButton: some View {
        Button(action: { missingFeature = "Recenter Map" }) {
            ZStack {
                Circle().fill(NeoBrutalistColor.primary)
                Image(systemName: "scope")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)
            .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(filled ? NeoBrutalistColor.onPrimary : NeoBrutalistColor.onSurface)
                .padding(.horizontal, NeoBrutalistSpacing.xs)
                .padding(.vertical, NeoBrutalistSpacing.xs)
                .frame(maxWidth: .infinity)
                .background(filled ? NeoBrutalistColor.primary : NeoBrutalistColor.surface)
                .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 4)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 4))
    }
}

struct ArboretumNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        ArboretumNeoBrutalistView()
    }
}
