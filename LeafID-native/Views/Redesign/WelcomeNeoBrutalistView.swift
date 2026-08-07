//
//  WelcomeNeoBrutalistView.swift
//  LeafID-native
//
//  Pilot screen for the neo-brutalist redesign (Track B) — a 1:1 SwiftUI build of
//  stitch_botanical_explorer/welcome_to_leaf_id/code.html, proving out NeoBrutalistTheme's
//  fonts/tokens/hard-shadow system before rolling out to the other 5 mockup-covered screens.
//  Hero image is the mockup's own placeholder art, not final production illustration.
//

import SwiftUI

struct WelcomeNeoBrutalistView: View {
    var onStartIdentifying: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroVisual
                .padding(.top, NeoBrutalistSpacing.sm)

            typographyBlock
                .padding(.top, NeoBrutalistSpacing.md)

            Spacer(minLength: NeoBrutalistSpacing.xl)

            startIdentifyingButton
                .padding(.bottom, NeoBrutalistSpacing.md)
        }
        .padding(.horizontal, NeoBrutalistSpacing.md)
        .padding(.vertical, NeoBrutalistSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
    }

    // MARK: - Hero

    private var heroVisual: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geo in
                Image("WelcomeHeroPlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .aspectRatio(4.0 / 5.0, contentMode: .fit)
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 12)

            druidStatusChip
                .offset(x: 8, y: 16)
        }
    }

    private var druidStatusChip: some View {
        HStack(spacing: NeoBrutalistSpacing.xs) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 13, weight: .bold))
            Text(String(localized: "Druid Status: Unlocked"))
                .font(NeoBrutalistFont.labelCaps())
                .kerning(1.2)
                .textCase(.uppercase)
        }
        .foregroundStyle(NeoBrutalistColor.onTertiaryContainer)
        .padding(.horizontal, NeoBrutalistSpacing.md)
        .padding(.vertical, NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.tertiaryContainer)
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 6)
    }

    // MARK: - Typography

    private var typographyBlock: some View {
        VStack(alignment: .leading, spacing: NeoBrutalistSpacing.sm) {
            VStack(alignment: .leading, spacing: 0) {
                Text("LEAF ID:")
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                Text("BOTANICAL")
                    .foregroundStyle(NeoBrutalistColor.primary)
                Text("DISCOVERY,")
                    .foregroundStyle(NeoBrutalistColor.onSurface)
                Text("URBAN STYLE.")
                    .foregroundStyle(NeoBrutalistColor.onSurface)
            }
            .font(NeoBrutalistFont.headlineLgMobile())
            .lineSpacing(2)

            (
                Text("Transform your city walks into a botanical journey. Scan urban flora, tag your territory, and level up from novice to an elite street ")
                + Text("Druid").fontWeight(.bold)
                + Text(".")
            )
            .font(NeoBrutalistFont.bodyLg())
            .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
            .padding(.top, NeoBrutalistSpacing.xs)
        }
    }

    // MARK: - CTA

    private var startIdentifyingButton: some View {
        Button(action: onStartIdentifying) {
            HStack(spacing: NeoBrutalistSpacing.sm) {
                Text(String(localized: "Start Identifying"))
                Image(systemName: "bolt.fill")
            }
            .font(NeoBrutalistFont.labelCaps())
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundStyle(NeoBrutalistColor.onPrimaryContainer)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(NeoBrutalistColor.primaryContainer)
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 8)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 8))
    }
}

struct WelcomeNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeNeoBrutalistView()
    }
}
