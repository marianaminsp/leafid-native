//
//  HerbariumNeoBrutalistView.swift
//  LeafID-native
//
//  Fifth redesign screen — a 1:1 SwiftUI build of stitch_botanical_explorer/your_herbarium/code.html
//  (the Collection tab's promotional/teaser state: a tilted trading-card collage). This is the
//  concept screen, not the real specimen grid — leaf art is approximated with SF Symbols in place of
//  the mockup's flat illustrated leaf art, since those are simple graphic icons, not photos.
//

import SwiftUI

struct HerbariumNeoBrutalistView: View {
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @State private var missingFeature: String?

    var body: some View {
        VStack(spacing: 0) {
            NeoBrutalistAppHeader(onAvatarTap: { onSelectTab(.druid) })

            ScrollView {
                VStack(spacing: NeoBrutalistSpacing.lg) {
                    headline
                    cardCollage
                    viewFolioButton
                }
                .padding(.horizontal, NeoBrutalistSpacing.md)
                .padding(.top, NeoBrutalistSpacing.lg)
                .padding(.bottom, NeoBrutalistSpacing.lg)
            }

            NeoBrutalistTabBar(activeTab: .collection, onSelect: onSelectTab)
        }
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Headline

    private var headline: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: NeoBrutalistSpacing.sm) {
                VStack(spacing: 4) {
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
                }

                Text("Preserve your discoveries in your personal digital forest.")
                    .font(NeoBrutalistFont.bodyLg())
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(NeoBrutalistSpacing.sm)
                    .background(NeoBrutalistColor.surface)
                    .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 2)
            }
            .padding(.top, NeoBrutalistSpacing.md)

            Text("NEW CARDS!")
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

    // MARK: - Card collage

    private var cardCollage: some View {
        ZStack {
            leafCard(latin: "ACER RUBRUM", name: "Red Maple", symbol: "leaf.fill", backdrop: NeoBrutalistColor.secondaryContainer, width: 128, height: 176)
                .rotationEffect(.degrees(-12))
                .offset(x: -70, y: -10)
                .onTapGesture { missingFeature = "Botanical Card (Red Maple)" }

            leafCard(latin: "QUERCUS ALBA", name: "White Oak", symbol: "leaf.fill", backdrop: NeoBrutalistColor.tertiaryContainer, width: 128, height: 176)
                .rotationEffect(.degrees(12))
                .offset(x: 70, y: 20)
                .onTapGesture { missingFeature = "Botanical Card (White Oak)" }

            featuredCard
                .offset(y: 60)
                .onTapGesture { missingFeature = "Botanical Card (Swiss Cheese)" }
        }
        .frame(height: 340)
        .padding(.top, NeoBrutalistSpacing.md)
    }

    private func leafCard(latin: String, name: String, symbol: String, backdrop: Color, width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack {
                backdrop
                Image(systemName: symbol)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(NeoBrutalistColor.ink.opacity(0.75))
            }
            .frame(height: height * 0.65)

            VStack(alignment: .leading, spacing: 1) {
                Text(latin)
                    .font(.custom("SpaceMono-Bold", size: 9))
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                Text(name)
                    .font(NeoBrutalistFont.bodyMedium(size: 13))
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, NeoBrutalistSpacing.xs)
            .frame(height: height * 0.35)
            .background(NeoBrutalistColor.surface)
        }
        .frame(width: width, height: height)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 4)
    }

    private var featuredCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ZStack {
                    NeoBrutalistColor.surface
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(NeoBrutalistColor.primary)
                }
                .frame(height: 130)

                VStack(spacing: 6) {
                    Text("YOUR HERBARIUM")
                        .font(.custom("SpaceMono-Bold", size: 11))
                        .foregroundStyle(NeoBrutalistColor.onSurface)
                }
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .background(NeoBrutalistColor.surface)
                .overlay(alignment: .top) {
                    Rectangle().fill(NeoBrutalistColor.ink).frame(height: NeoBrutalistStroke.heavy)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("MONSTERA D.")
                        .font(.custom("SpaceMono-Bold", size: 10))
                        .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                        .padding(.horizontal, 4)
                        .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: 1))
                    HStack {
                        Text("Swiss Cheese")
                            .font(NeoBrutalistFont.headlineMd())
                            .foregroundStyle(NeoBrutalistColor.onSurface)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Spacer()
                    }
                    HStack {
                        Text("LVL 4")
                            .font(.custom("SpaceMono-Bold", size: 12))
                            .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
                        Spacer()
                        Circle().fill(NeoBrutalistColor.primary).frame(width: 14, height: 14)
                    }
                }
                .padding(NeoBrutalistSpacing.sm)
                .background(NeoBrutalistColor.surfaceContainer)
            }
            .frame(width: 168, height: 260)
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 6)

            ZStack {
                Circle().fill(NeoBrutalistColor.secondary)
                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(NeoBrutalistColor.onSecondary)
            }
            .frame(width: 32, height: 32)
            .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
            .offset(x: 12, y: -12)
        }
    }

    // MARK: - CTA

    private var viewFolioButton: some View {
        Button(action: { missingFeature = "View My Folio" }) {
            HStack(spacing: NeoBrutalistSpacing.sm) {
                Image(systemName: "bookmark.fill")
                Text("View My Folio")
            }
            .font(NeoBrutalistFont.headlineMd())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(NeoBrutalistColor.primary)
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 6)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 6))
        .padding(.top, NeoBrutalistSpacing.xl)
    }
}

struct HerbariumNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        HerbariumNeoBrutalistView()
    }
}
