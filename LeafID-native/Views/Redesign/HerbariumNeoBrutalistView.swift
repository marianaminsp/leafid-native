//
//  HerbariumNeoBrutalistView.swift
//  LeafID-native
//
//  Fifth redesign screen, rebuilt against artifacts "Herbarium Empty State" and "Herbarium
//  Sticker Pile" (2026-08-07/08). Two states driven by the shared
//  `RedesignPrototypeState.hasDiscoveries` flag:
//
//  - Empty: a promotional card collage (Bird of Paradise / Dragon Fruit / African Mask, real
//    reference illustrations, per-card accent colors) inviting the first scan. Fits the
//    viewport with no scroll — headline and CTA are fixed height, the collage is the one
//    flexible element that absorbs whatever space is left.
//  - Populated: Sticker Pile — the *final* design (overrides the source artifacts' own framing
//    of List as "the decided baseline"). Drag any sticker to shuffle the pile; flick it upward
//    past the open threshold to open the Botanical Card via matchedGeometryEffect. Every sticker
//    uses the same card construction as the empty-state collage (photo + colored name strip),
//    not a bare image.
//

import SwiftUI

struct HerbariumNeoBrutalistView: View {
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @EnvironmentObject private var prototypeState: RedesignPrototypeState
    @State private var missingFeature: String?
    @Namespace private var cardNamespace
    @State private var selectedSpecimen: HerbariumSpecimen?

    private var specimens: [HerbariumSpecimen] { HerbariumSpecimen.sample }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if prototypeState.hasDiscoveries {
                    stickerPile
                } else {
                    emptyState
                }

                if let specimen = selectedSpecimen {
                    cardOverlay(for: specimen)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            NeoBrutalistTabBar(activeTab: .collection, onSelect: onSelectTab)
        }
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: NeoBrutalistSpacing.lg) {
            headline
            cardCollage
            viewFolioButton
        }
        .padding(.horizontal, NeoBrutalistSpacing.md)
        .padding(.top, NeoBrutalistSpacing.md)
        .padding(.bottom, NeoBrutalistSpacing.md)
    }

    private var headline: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                Text("BUILD YOUR")
                    .font(NeoBrutalistFont.headlineLgMobile())
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                Text("HERBARIUM")
                    .font(NeoBrutalistFont.headlineLgMobile())
                    .foregroundStyle(NeoBrutalistColor.onPrimaryContainer)
                    .padding(.horizontal, NeoBrutalistSpacing.sm)
                    .padding(.vertical, NeoBrutalistSpacing.xs)
                    .background(NeoBrutalistColor.primaryContainer)
                    .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 4)
                    .rotationEffect(.degrees(-2))

                Text("Preserve your discoveries in your personal digital forest.")
                    .font(NeoBrutalistFont.bodyMd())
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.top, NeoBrutalistSpacing.xs)
            }
            .padding(.top, NeoBrutalistSpacing.md)

            Text("FRESH SPECIMENS")
                .font(.custom("SpaceMono-Bold", size: 11))
                .foregroundStyle(NeoBrutalistColor.onTertiaryContainer)
                .padding(.horizontal, NeoBrutalistSpacing.sm)
                .padding(.vertical, NeoBrutalistSpacing.xs)
                .background(NeoBrutalistColor.tertiaryContainer)
                .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 3)
                .rotationEffect(.degrees(8))
                .offset(x: -8, y: -4)
        }
    }

    private var cardCollage: some View {
        ZStack {
            collageCard(specimen: specimens[1], width: 108, height: 148)
                .rotationEffect(.degrees(-10))
                .offset(x: -76, y: 6)
                .onTapGesture { missingFeature = "Botanical Card (\(specimens[1].commonName))" }

            collageCard(specimen: specimens[2], width: 108, height: 148)
                .rotationEffect(.degrees(9))
                .offset(x: 76, y: -6)
                .onTapGesture { missingFeature = "Botanical Card (\(specimens[2].commonName))" }

            ZStack(alignment: .topTrailing) {
                collageCard(specimen: specimens[3], width: 126, height: 174)
                ZStack {
                    Circle().fill(NeoBrutalistColor.secondary)
                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(NeoBrutalistColor.onSecondary)
                }
                .frame(width: 30, height: 30)
                .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                .offset(x: 10, y: -10)
            }
            .onTapGesture { missingFeature = "Botanical Card (\(specimens[3].commonName))" }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func collageCard(specimen: HerbariumSpecimen, width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Image(specimen.imageAsset)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height * 0.72)
                .clipped()
            Text(specimen.commonName.uppercased())
                .font(.custom("SpaceMono-Bold", size: 9))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: height * 0.28)
                .background(specimen.accent)
        }
        .frame(width: width, height: height)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 4)
    }

    private var viewFolioButton: some View {
        Button(action: { missingFeature = "View My Folio" }) {
            HStack(spacing: NeoBrutalistSpacing.sm) {
                Image(systemName: "bookmark.fill")
                Text("View My Folio")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .font(NeoBrutalistFont.headlineMd())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(NeoBrutalistColor.primary)
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 6)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 6))
    }

    // MARK: - Populated: Sticker Pile

    private var stickerPile: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("HERBARIUM")
                    .font(.custom("SpaceMono-Bold", size: 13))
                    .kerning(1)
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                Spacer()
                Text("\(specimens.count) SPECIMENS")
                    .font(.custom("SpaceMono-Bold", size: 10))
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
            }
            .padding(.horizontal, NeoBrutalistSpacing.md)
            .padding(.top, NeoBrutalistSpacing.md)

            StickerPileView(
                specimens: specimens,
                namespace: cardNamespace,
                onOpen: openCard
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func openCard(_ specimen: HerbariumSpecimen) {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            selectedSpecimen = specimen
        }
    }

    private func closeCard() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
            selectedSpecimen = nil
        }
    }

    // MARK: - Card overlay

    private func cardOverlay(for specimen: HerbariumSpecimen) -> some View {
        ZStack {
            NeoBrutalistColor.ink.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { closeCard() }

            BotanicalCardNeoBrutalistView(specimen: specimen, namespace: cardNamespace, onClose: closeCard)
                .padding(.horizontal, NeoBrutalistSpacing.md)
                .padding(.top, NeoBrutalistSpacing.xl)
                .padding(.bottom, NeoBrutalistSpacing.lg)
        }
        .transition(.opacity)
    }
}

/// Drag-to-shuffle, flick-up-to-open sticker pile — irregular scatter, small random tilt, no
/// snapping grid. Picking a sticker up bumps it to the front instantly (z-index only, no
/// animation — physical objects don't animate when touched). A bouncing arrow hint disappears
/// on first touch and never returns.
private struct StickerPileView: View {
    let specimens: [HerbariumSpecimen]
    var namespace: Namespace.ID
    var onOpen: (HerbariumSpecimen) -> Void

    @State private var frontID: UUID?
    @State private var hasTouched = false

    private static let layout: [(x: CGFloat, y: CGFloat, rotation: Double)] = [
        (0.22, 0.16, -9), (0.68, 0.30, 6), (0.30, 0.60, 11), (0.72, 0.72, -7),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(specimens.enumerated()), id: \.element.id) { index, specimen in
                    let spot = Self.layout[index % Self.layout.count]
                    StickerCard(
                        specimen: specimen,
                        namespace: namespace,
                        basePosition: CGPoint(x: geo.size.width * spot.x, y: geo.size.height * spot.y),
                        baseRotation: spot.rotation,
                        isFront: frontID == specimen.id,
                        onBringToFront: { frontID = specimen.id },
                        onFirstTouch: { hasTouched = true },
                        onOpen: { onOpen(specimen) }
                    )
                }

                if !hasTouched {
                    VStack(spacing: NeoBrutalistSpacing.xs) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                        Text("FLICK A CARD UP TO OPEN")
                            .font(.custom("SpaceMono-Bold", size: 10))
                            .kerning(0.6)
                    }
                    .foregroundStyle(NeoBrutalistColor.outline)
                    .position(x: geo.size.width / 2, y: geo.size.height - 24)
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

private struct StickerCard: View {
    let specimen: HerbariumSpecimen
    var namespace: Namespace.ID
    let basePosition: CGPoint
    let baseRotation: Double
    let isFront: Bool
    var onBringToFront: () -> Void
    var onFirstTouch: () -> Void
    var onOpen: () -> Void

    @State private var settledOffset: CGSize = .zero
    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false

    private let openThreshold: CGFloat = -110
    private let cardWidth: CGFloat = 92
    private let cardHeight: CGFloat = 120

    private var currentOffset: CGSize {
        CGSize(width: settledOffset.width + dragTranslation.width, height: settledOffset.height + dragTranslation.height)
    }

    private var crossedOpenThreshold: Bool {
        currentOffset.height < openThreshold
    }

    var body: some View {
        VStack(spacing: 0) {
            Image(specimen.imageAsset)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: cardHeight * 0.7)
                .clipped()
                .matchedGeometryEffect(id: specimen.id, in: namespace)
            Text(specimen.commonName.uppercased())
                .font(.custom("SpaceMono-Bold", size: 8.5))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: cardHeight * 0.3)
                .background(specimen.accent)
        }
        .frame(width: cardWidth, height: cardHeight)
        .neoBrutalistSurface(
            borderWidth: NeoBrutalistStroke.default,
            shadowOffset: 3,
            shadowColor: crossedOpenThreshold ? NeoBrutalistColor.primaryContainer : NeoBrutalistColor.ink
        )
        .rotationEffect(.degrees(baseRotation))
        .position(x: basePosition.x + currentOffset.width, y: basePosition.y + currentOffset.height)
        .zIndex(isFront ? 10 : 0)
        .animation(.easeOut(duration: 0.15), value: crossedOpenThreshold)
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .local)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        onBringToFront()
                        onFirstTouch()
                    }
                    dragTranslation = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    let finalOffsetY = settledOffset.height + value.translation.height
                    let flickFast = value.predictedEndTranslation.height < -400
                    if finalOffsetY < openThreshold || flickFast {
                        dragTranslation = .zero
                        onOpen()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            settledOffset.width += value.translation.width
                            settledOffset.height += value.translation.height
                            dragTranslation = .zero
                        }
                    }
                }
        )
    }
}

struct HerbariumNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        HerbariumNeoBrutalistView()
            .environmentObject(RedesignPrototypeState())
    }
}
