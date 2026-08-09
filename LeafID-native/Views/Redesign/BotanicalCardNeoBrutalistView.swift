//
//  BotanicalCardNeoBrutalistView.swift
//  LeafID-native
//
//  Rebuilt against artifact "Herbarium → Botanical Card Transition" (2026-08-08), corrected after
//  review: the neo-brutalist successor to the *real* `BotanicalCardImmersiveView` data model
//  (Colour Signature, Traditional Name, Botanical Spirit, Ethnobotany, Cultural Legacy) — not the
//  Type/Light/Watering gardening facts the source artifact copied from the stale
//  docs/ui-screens/BotanicalCard.md. Hard 2-3px ink border, 0 corner radius, hard offset shadow.
//
//  Presented as a card, not a full screen — the caller (HerbariumNeoBrutalistView) insets it from
//  the screen edges over a dimmed backdrop. Close and flip are floating circular buttons that sit
//  INSIDE this view's own bounds (top-right / bottom-right corners), not outside them.
//
//  Flip uses opacity-crossfade + rotation3DEffect, same technique as BotanicalCardImmersiveView
//  and the Scanner reveal — sidesteps the source artifact's browser-only backface-visibility bug
//  outright. Motion token: Flip = .spring(response: 0.5, dampingFraction: 0.75).
//

import SwiftUI

struct BotanicalCardNeoBrutalistView: View {
    let specimen: HerbariumSpecimen
    var namespace: Namespace.ID
    var onClose: () -> Void

    @State private var isFlipped = false

    var body: some View {
        ZStack {
            cardFront
                .opacity(isFlipped ? 0 : 1)
            cardBack
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center,
            perspective: 0.5
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isFlipped)
    }

    // MARK: - Front

    private var cardFront: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(specimen.imageAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .matchedGeometryEffect(id: specimen.id, in: namespace)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(NeoBrutalistColor.ink).frame(height: NeoBrutalistStroke.heavy)
                    }
                closeButton
                    .padding(NeoBrutalistSpacing.xs)
            }

            VStack(alignment: .leading, spacing: NeoBrutalistSpacing.sm) {
                Text(specimen.chip)
                    .font(.custom("SpaceMono-Bold", size: 10))
                    .kerning(1)
                    .foregroundStyle(NeoBrutalistColor.onPrimary)
                    .padding(.horizontal, NeoBrutalistSpacing.xs)
                    .padding(.vertical, 4)
                    .background(NeoBrutalistColor.primary)

                Text(specimen.commonName)
                    .font(NeoBrutalistFont.headlineLg())
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(specimen.latinName.localizedCapitalized)
                    .font(.custom("SpaceMono-Bold", size: 12))
                    .italic()
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)

                Spacer(minLength: 0)
            }
            .padding(NeoBrutalistSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NeoBrutalistColor.surface)
            .overlay(alignment: .bottomTrailing) {
                flipButton.padding(NeoBrutalistSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 8)
    }

    // MARK: - Back

    private var cardBack: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: NeoBrutalistSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(specimen.commonName)
                            .font(NeoBrutalistFont.headlineMd())
                            .foregroundStyle(NeoBrutalistColor.onSurface)
                        Text(specimen.latinName.localizedCapitalized)
                            .font(.custom("SpaceMono-Bold", size: 11))
                            .italic()
                            .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                        if let traditionalName = specimen.traditionalName {
                            Text("Known as “\(traditionalName)”")
                                .font(NeoBrutalistFont.bodyMedium(size: 12))
                                .italic()
                                .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                        }
                    }

                    sectionLabel("COLOUR SIGNATURE")
                    HStack(spacing: NeoBrutalistSpacing.sm) {
                        ForEach(specimen.paletteHexes, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: UInt32(hex.replacingOccurrences(of: "#", with: ""), radix: 16) ?? 0x000000))
                                .frame(width: 22, height: 22)
                                .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                        }
                    }

                    sectionLabel("BOTANICAL SPIRIT")
                    Text("“\(specimen.botanicalSpirit)”")
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(NeoBrutalistColor.onSurface)
                        .padding(NeoBrutalistSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))

                    sectionLabel("ETHNOBOTANY")
                    Text(specimen.ethnobotany)
                        .font(NeoBrutalistFont.bodyMd())
                        .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)

                    sectionLabel("CULTURAL LEGACY")
                    Text(specimen.culturalLegacy)
                        .font(NeoBrutalistFont.bodyMd())
                        .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(NeoBrutalistSpacing.md)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
        .background(NeoBrutalistColor.surface)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 8)
        .overlay(alignment: .topTrailing) {
            closeButton.padding(NeoBrutalistSpacing.xs)
        }
        .overlay(alignment: .bottomTrailing) {
            flipButton.padding(NeoBrutalistSpacing.xs)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("SpaceMono-Bold", size: 10))
            .kerning(1.2)
            .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
    }

    // MARK: - Controls (both float INSIDE the card's own bounds)

    private var flipButton: some View {
        Button {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            isFlipped.toggle()
        } label: {
            ZStack {
                Circle().fill(NeoBrutalistColor.primary)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(NeoBrutalistColor.onPrimary)
            }
            .frame(width: 32, height: 32)
            .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 2))
    }

    private var closeButton: some View {
        Button(action: onClose) {
            ZStack {
                Circle().fill(NeoBrutalistColor.surface.opacity(0.92))
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(NeoBrutalistColor.onSurface)
            }
            .frame(width: 28, height: 28)
            .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 2))
    }
}
