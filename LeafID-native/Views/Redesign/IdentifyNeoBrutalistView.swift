//
//  IdentifyNeoBrutalistView.swift
//  LeafID-native
//
//  Second redesign screen — the app's Home/Identify tab. Rebuilt against the "Leaf ID — Redesign
//  Build Spec" artifact (2026-08-09): reads the shared `RedesignPrototypeState.hasDiscoveries`
//  flag (same flag Herbarium/Druid use, flipped by Scanner's "Save to Herbarium") to show a
//  first-time "Folio: Empty" state or a returning "Last Discovery" state. Zero-scroll — the hero
//  card is the one flexible element, headline and CTA row size to content, so this fits any
//  device height without a ScrollView (root cause of the old scroll bug was a fixed aspect ratio
//  on the card).
//

import SwiftUI

struct IdentifyNeoBrutalistView: View {
    var onOpenScanner: () -> Void = {}
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @EnvironmentObject private var prototypeState: RedesignPrototypeState
    @State private var missingFeature: String?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: NeoBrutalistSpacing.lg) {
                headline
                heroCard
                ctaRow
            }
            .padding(.horizontal, NeoBrutalistSpacing.md)
            .padding(.top, NeoBrutalistSpacing.md)
            .padding(.bottom, NeoBrutalistSpacing.md)

            NeoBrutalistTabBar(activeTab: .identify, onSelect: onSelectTab)
        }
        .animation(.none, value: prototypeState.hasDiscoveries)
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Headline

    /// First-time: full marketing headline + subhead, carries the invitation to act. Returning:
    /// a small mono-caps utility label — same class as Herbarium's populated header — so the Last
    /// Discovery card gets the space instead of repeating copy a returning user has already seen.
    @ViewBuilder
    private var headline: some View {
        if prototypeState.hasDiscoveries {
            Text("IDENTIFY")
                .font(.custom("SpaceMono-Bold", size: 13))
                .kerning(1)
                .foregroundStyle(NeoBrutalistColor.onSurface)
        } else {
            VStack(alignment: .leading, spacing: NeoBrutalistSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("IDENTIFY THE")
                        .font(NeoBrutalistFont.headlineLgMobile())
                        .foregroundStyle(NeoBrutalistColor.onSurface)
                    Text("STREETS.")
                        .font(NeoBrutalistFont.headlineLgMobile())
                        .foregroundStyle(NeoBrutalistColor.onPrimaryContainer)
                        .padding(.horizontal, NeoBrutalistSpacing.sm)
                        .padding(.vertical, NeoBrutalistSpacing.xs)
                        .background(NeoBrutalistColor.primaryContainer)
                        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 4)
                        .rotationEffect(.degrees(-2))
                }

                Text("Identify any tree or plant in seconds with our Botanist AI. Keep it crunchy, keep it green.")
                    .font(NeoBrutalistFont.bodyLg())
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                    .padding(.leading, NeoBrutalistSpacing.md)
                    .overlay(alignment: .leading) {
                        // A bare `Rectangle` as an HStack sibling expands to fill any leftover
                        // flexible space in this screen's zero-scroll layout (competing with the
                        // hero card below for height); overlaying it against the Text's own
                        // resolved bounds keeps it pinned to exactly the text's height instead.
                        Rectangle()
                            .fill(NeoBrutalistColor.ink)
                            .frame(width: 4)
                    }
            }
        }
    }

    // MARK: - Hero card

    @ViewBuilder
    private var heroCard: some View {
        if prototypeState.hasDiscoveries {
            lastDiscoveryCard
        } else {
            folioEmptyCard
        }
    }

    /// Returning user: the last scan's photo, labeled as a result — not a live scan. No reticle,
    /// no "AI ACTIVE": nothing here is "in progress" about a photo from an earlier session.
    private var lastDiscoveryCard: some View {
        ZStack {
            GeometryReader { geo in
                Image("SamaraLastDiscovery")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }

            VStack {
                HStack {
                    Spacer()
                    heroBadge("LAST DISCOVERY")
                }
                Spacer()
                lastDiscoveryResultTag
            }
            .padding(NeoBrutalistSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 8)
        .contentShape(Rectangle())
        .onTapGesture { missingFeature = "Botanical Card (Acer Samara)" }
    }

    private var lastDiscoveryResultTag: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SPECIMEN IDENTIFIED")
                .font(.custom("SpaceMono-Bold", size: 11))
                .kerning(1.2)
                .foregroundStyle(NeoBrutalistColor.primaryContainer)
            Text("Acer Samara — Maple Seed Pod")
                .font(NeoBrutalistFont.bodyMd())
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.ink.opacity(0.85))
        .overlay(Rectangle().strokeBorder(NeoBrutalistColor.primaryContainer, lineWidth: NeoBrutalistStroke.default))
    }

    /// First-time user: no photo exists, so the card doesn't fake one — a dashed drop-zone framing
    /// a small illustration card, not a placeholder icon.
    private var folioEmptyCard: some View {
        ZStack {
            VStack(spacing: NeoBrutalistSpacing.lg) {
                heroBadge("FOLIO: EMPTY")
                Spacer(minLength: 0)
                Image("SamaraLastDiscovery")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 168, height: 210)
                    .clipped()
                    .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 4)
                Spacer(minLength: 0)
                Text("NO DISCOVERIES YET")
                    .font(NeoBrutalistFont.headlineMd())
                    .foregroundStyle(NeoBrutalistColor.onSurface)
            }
            .padding(NeoBrutalistSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NeoBrutalistColor.surfaceContainer)
        .overlay(
            Rectangle().strokeBorder(
                NeoBrutalistColor.outline,
                style: StrokeStyle(lineWidth: NeoBrutalistStroke.default, dash: [7, 5])
            )
        )
    }

    private func heroBadge(_ text: String) -> some View {
        Text(text)
            .font(.custom("SpaceMono-Bold", size: 11))
            .kerning(1.2)
            .foregroundStyle(NeoBrutalistColor.onSurface)
            .padding(.horizontal, NeoBrutalistSpacing.sm)
            .padding(.vertical, NeoBrutalistSpacing.xs)
            .background(NeoBrutalistColor.surface.opacity(0.92))
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
    }

    // MARK: - CTA row — Scan or Upload

    private var ctaRow: some View {
        HStack(spacing: NeoBrutalistSpacing.sm) {
            Button(action: onOpenScanner) {
                HStack(spacing: NeoBrutalistSpacing.sm) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 20, weight: .bold))
                    Text("Open Scanner")
                        .font(NeoBrutalistFont.headlineMd())
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(NeoBrutalistColor.primary)
                .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 6)
            }
            .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 6))

            Button(action: { missingFeature = "Photo Library Picker" }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                    .frame(width: 60, height: 60)
                    .background(NeoBrutalistColor.surface)
                    .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 6)
            }
            .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 6))
        }
    }
}

struct IdentifyNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyNeoBrutalistView()
            .environmentObject(RedesignPrototypeState())
    }
}
