//
//  IdentifyNeoBrutalistView.swift
//  LeafID-native
//
//  Second redesign screen — a 1:1 SwiftUI build of
//  stitch_botanical_explorer/identify_any_plant/code.html (the app's Home/Identify tab).
//  Hero photo is the mockup's own placeholder, not final production art.
//

import SwiftUI

struct IdentifyNeoBrutalistView: View {
    var onOpenScanner: () -> Void = {}
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @State private var missingFeature: String?

    var body: some View {
        VStack(spacing: 0) {
            NeoBrutalistAppHeader(onAvatarTap: { onSelectTab(.druid) })

            ScrollView {
                VStack(alignment: .leading, spacing: NeoBrutalistSpacing.lg) {
                    headline
                    scanCard
                    openScannerButton
                }
                .padding(.horizontal, NeoBrutalistSpacing.md)
                .padding(.top, NeoBrutalistSpacing.md)
                .padding(.bottom, NeoBrutalistSpacing.lg)
            }

            NeoBrutalistTabBar(activeTab: .identify, onSelect: onSelectTab)
        }
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(alignment: .leading, spacing: NeoBrutalistSpacing.md) {
            VStack(alignment: .leading, spacing: 0) {
                strokedDisplayLine("SCAN THE", color: NeoBrutalistColor.primaryContainer)
                strokedDisplayLine("STREETS.", color: NeoBrutalistColor.tertiaryContainer)
                    .padding(.leading, NeoBrutalistSpacing.xl)
            }

            HStack(alignment: .top, spacing: NeoBrutalistSpacing.md) {
                Rectangle()
                    .fill(NeoBrutalistColor.ink)
                    .frame(width: 4)
                Text("Identify any tree or plant in seconds with our Botanist AI. Keep it crunchy, keep it green.")
                    .font(NeoBrutalistFont.bodyLg())
                    .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
            }
        }
    }

    /// Approximates the mockup's `-webkit-text-stroke` + hard-drop-shadow display headline: a solid
    /// ink-colored copy offset behind the colored fill, since SwiftUI has no native text-stroke.
    private func strokedDisplayLine(_ text: String, color: Color) -> some View {
        ZStack(alignment: .leading) {
            Text(text)
                .foregroundStyle(NeoBrutalistColor.ink)
                .offset(x: 3, y: 3)
            Text(text)
                .foregroundStyle(color)
        }
        .font(NeoBrutalistFont.headlineLgMobile())
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - Scan card

    private var scanCard: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
                Image("IdentifyHeroPlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .aspectRatio(0.67, contentMode: .fit)

            VStack {
                HStack {
                    Spacer()
                    aiActiveBadge
                }
                Spacer()
                scanReticle
                Spacer()
                targetAcquiredCard
            }
            .padding(NeoBrutalistSpacing.md)
        }
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 8)
        .contentShape(Rectangle())
        .onTapGesture { missingFeature = "Scan Result" }
    }

    private var aiActiveBadge: some View {
        HStack(spacing: NeoBrutalistSpacing.xs) {
            Circle()
                .fill(NeoBrutalistColor.primaryContainer)
                .frame(width: 8, height: 8)
            Text("AI ACTIVE")
                .font(.custom("SpaceMono-Bold", size: 11))
                .kerning(1.2)
                .foregroundStyle(NeoBrutalistColor.onSurface)
        }
        .padding(.horizontal, NeoBrutalistSpacing.sm)
        .padding(.vertical, NeoBrutalistSpacing.xs)
        .background(NeoBrutalistColor.surface.opacity(0.92))
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
    }

    private var scanReticle: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { corner in
                ReticleCorner()
                    .stroke(NeoBrutalistColor.primaryContainer, lineWidth: 4)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(Double(corner) * 90))
                    .offset(
                        x: (corner == 1 || corner == 2) ? 44 : -44,
                        y: (corner == 2 || corner == 3) ? 44 : -44
                    )
            }
        }
        .frame(width: 128, height: 128)
        .opacity(0.85)
    }

    private var targetAcquiredCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("TARGET ACQUIRED")
                .font(.custom("SpaceMono-Bold", size: 11))
                .kerning(1.2)
                .foregroundStyle(NeoBrutalistColor.primaryContainer)
            Text("Monstera Deliciosa (var. unknown)")
                .font(NeoBrutalistFont.bodyMd())
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.ink.opacity(0.85))
        .overlay(Rectangle().strokeBorder(NeoBrutalistColor.primaryContainer, lineWidth: NeoBrutalistStroke.default))
    }

    // MARK: - CTA

    private var openScannerButton: some View {
        Button(action: onOpenScanner) {
            HStack(spacing: NeoBrutalistSpacing.sm) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 22, weight: .bold))
                Text("Open Scanner")
                    .font(NeoBrutalistFont.headlineMd())
            }
            .foregroundStyle(NeoBrutalistColor.onPrimaryContainer)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(NeoBrutalistColor.primaryContainer)
            .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.heavy, shadowOffset: 6)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 6))
    }
}

/// One right-angle corner bracket of the scan reticle; rotated per corner in `scanReticle`.
private struct ReticleCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

struct IdentifyNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyNeoBrutalistView()
    }
}
