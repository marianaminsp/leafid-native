//
//  BoutiqueHeader.swift
//  LeafID-native
//
//  Title: Plus Jakarta Sans `text-3xl` (30pt). Subtitle: Manrope `text-base` @ 60% opacity.
//  Chrome: liquid glass (legacy screens) or home strip (`code.html` header).
//

import SwiftUI

struct BoutiqueHeader: View {
    enum Layout {
        case stacked(plainTop: String, accentBottom: String)
        case inline(plainLeading: String, accentTrailing: String)
    }

    enum Chrome {
        case liquidGlass
        case homeStrip
    }

    let layout: Layout
    let subtitle: String
    var chrome: Chrome = .liquidGlass

    private var titleBlock: some View {
        Group {
            switch layout {
            case let .stacked(plainTop, accentBottom):
                VStack(alignment: .leading, spacing: 2) {
                    Text(plainTop)
                        .font(LeafIDFont.plusJakarta(size: LeafIDFont.boutiqueTitleSize, weight: .bold))
                        .tracking(-0.45)
                        .foregroundStyle(LeafIDTheme.onSurface)
                    Text(accentBottom)
                        .font(LeafIDFont.plusJakarta(size: LeafIDFont.boutiqueTitleSize, weight: .bold))
                        .tracking(-0.45)
                        .foregroundStyle(LeafIDTheme.primary)
                }
            case let .inline(plainLeading, accentTrailing):
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(plainLeading)
                        .font(LeafIDFont.plusJakarta(size: LeafIDFont.boutiqueTitleSize, weight: .bold))
                        .tracking(-0.45)
                        .foregroundStyle(LeafIDTheme.onSurface)
                    Text(accentTrailing)
                        .font(LeafIDFont.plusJakarta(size: LeafIDFont.boutiqueTitleSize, weight: .bold))
                        .tracking(-0.45)
                        .foregroundStyle(LeafIDTheme.primary)
                }
            }
        }
    }

    var body: some View {
        let stack = VStack(alignment: .leading, spacing: LeafIDTheme.space10) {
            titleBlock
            Text(subtitle)
                .font(LeafIDFont.manrope(size: LeafIDFont.boutiqueSubtitleSize, weight: .medium))
                .foregroundStyle(LeafIDTheme.onSurface.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        switch chrome {
        case .liquidGlass:
            stack
                .padding(LeafIDTheme.space24)
                .liquidGlass()
        case .homeStrip:
            stack
                .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                .padding(.vertical, LeafIDTheme.space16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LeafIDTheme.surface)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(LeafIDTheme.outlineVariant.opacity(0.1))
                        .frame(height: 1)
                }
        }
    }
}
