//
//  DruidNeoBrutalistView.swift
//  LeafID-native
//
//  Sixth redesign screen — rebuilt against artifact "Leaf ID — Druid: Populated vs Empty"
//  (2026-08-08): no header (the Druid tab itself is the only identity marker needed), no
//  profile photo — a big colored rank title stands in as the visual anchor instead — and
//  real illustrated badge medallions (desaturated + a corner lock badge when locked, rather
//  than a plain padlock icon) instead of the original mockup's placeholder art.
//
//  Two states, both real progress and zero progress, since badge-earning logic isn't wired
//  yet and every user is currently in the empty state. Reads the shared
//  `RedesignPrototypeState.hasDiscoveries` flag (flipped by Save to Herbarium on the Scanner
//  Reveal card) rather than an independent local toggle, so all three stateful screens move
//  together.
//

import SwiftUI

struct DruidNeoBrutalistView: View {
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @EnvironmentObject private var prototypeState: RedesignPrototypeState
    @State private var missingFeature: String?
    private var isPopulated: Bool { prototypeState.hasDiscoveries }

    var body: some View {
        VStack(spacing: 0) {
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

    // MARK: - Profile header

    private var profileHeader: some View {
        VStack(spacing: NeoBrutalistSpacing.sm) {
            Text(isPopulated ? "ELDER DRUID" : "SEEDLING DRUID")
                .font(NeoBrutalistFont.headlineLgMobile())
                .foregroundStyle(NeoBrutalistColor.primary)
                .multilineTextAlignment(.center)

            Text("@UrbanForager_99")
                .font(.custom("SpaceMono-Bold", size: 12))
                .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)

            Text(isPopulated ? "LVL 24" : "LVL 1")
                .font(.custom("SpaceMono-Bold", size: 12))
                .foregroundStyle(NeoBrutalistColor.onSecondary)
                .padding(.horizontal, NeoBrutalistSpacing.sm)
                .padding(.vertical, NeoBrutalistSpacing.xs)
                .background(NeoBrutalistColor.secondary)
                .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                .padding(.top, NeoBrutalistSpacing.xs)

            xpBar
                .padding(.top, NeoBrutalistSpacing.md)
            Text(isPopulated ? "8,240 / 10,000 XP" : "0 / 500 XP")
                .font(.custom("SpaceMono-Bold", size: 10.5))
                .kerning(1)
                .foregroundStyle(NeoBrutalistColor.onSurfaceVariant)
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
                    .frame(width: geo.size.width * (isPopulated ? 0.82 : 0.0))
            }
        }
        .frame(height: 20)
        .overlay(Rectangle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: NeoBrutalistSpacing.md) {
            statTile(icon: "mappin.and.ellipse", iconColor: NeoBrutalistColor.tertiary, value: isPopulated ? "142" : "0", label: "Discoveries\nRooted")
            statTile(icon: "leaf.fill", iconColor: NeoBrutalistColor.secondary, value: isPopulated ? "38" : "0", label: "Ancient Seeds\nCollected")
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
                badgeCard(
                    kind: .nightshadeNav,
                    title: "NIGHTSHADE NAV",
                    subtitle: isPopulated ? "FOUND 10 TOXIC FLORA" : "FOUND 10 TOXIC FLORA (0/10)",
                    unlocked: isPopulated
                )
                badgeCard(
                    kind: .concreteJungle,
                    title: "CONCRETE JUNGLE",
                    subtitle: isPopulated ? "LOGGED 50 CITY WEEDS" : "LOG 50 CITY WEEDS (0/50)",
                    unlocked: isPopulated
                )
                badgeCard(
                    kind: .mycologist,
                    title: "MYCOLOGIST",
                    subtitle: isPopulated ? "ID 20 FUNGI (14/20)" : "ID 20 FUNGI (0/20)",
                    unlocked: false
                )
                badgeCard(
                    kind: .sunWalker,
                    title: "SUN WALKER",
                    subtitle: "LOG 5 DESERT PLANTS (0/5)",
                    unlocked: false
                )
            }
        }
    }

    private func badgeCard(kind: BadgeMedallion.Kind, title: String, subtitle: String, unlocked: Bool) -> some View {
        VStack(spacing: NeoBrutalistSpacing.sm) {
            ZStack(alignment: .bottomTrailing) {
                BadgeMedallion(kind: kind)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                    .saturation(unlocked ? 1 : 0)
                    .brightness(unlocked ? 0 : 0.15)

                if !unlocked {
                    ZStack {
                        Circle().fill(NeoBrutalistColor.surface)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(NeoBrutalistColor.onSurface)
                    }
                    .frame(width: 20, height: 20)
                    .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                    .offset(x: 2, y: 2)
                }
            }

            Text(title)
                .font(NeoBrutalistFont.bodyMedium(size: 14))
                .foregroundStyle(unlocked ? NeoBrutalistColor.onSurface : NeoBrutalistColor.outline)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.custom("SpaceMono-Bold", size: 9))
                .foregroundStyle(unlocked ? NeoBrutalistColor.onSurfaceVariant : NeoBrutalistColor.outline)
                .multilineTextAlignment(.center)
        }
        .padding(NeoBrutalistSpacing.md)
        .frame(maxWidth: .infinity)
        .background(unlocked ? NeoBrutalistColor.surfaceContainerHighest : NeoBrutalistColor.surfaceContainer.opacity(0.7))
        .neoBrutalistSurface(
            borderWidth: NeoBrutalistStroke.default,
            shadowOffset: unlocked ? 6 : 4,
            shadowColor: unlocked ? kind.accent : NeoBrutalistColor.outlineVariant
        )
        .contentShape(Rectangle())
        .onTapGesture { missingFeature = "Badge Detail (\(title))" }
    }
}

/// Illustrated badge medallions from artifact "Druid: Populated vs Empty" — geometric line-icons
/// (nightshade flower, sprout-in-pavement, mushroom, sun+cactus), each with its own ground color,
/// drawn directly rather than shipped as image assets since no badge art has been commissioned yet.
private struct BadgeMedallion: View {
    enum Kind {
        case nightshadeNav, concreteJungle, mycologist, sunWalker

        var accent: Color {
            switch self {
            case .nightshadeNav: return NeoBrutalistColor.tertiary
            case .concreteJungle: return NeoBrutalistColor.secondary
            case .mycologist: return NeoBrutalistColor.secondary
            case .sunWalker: return NeoBrutalistColor.primary
            }
        }
    }

    let kind: Kind

    var body: some View {
        Canvas { context, size in
            let scale = size.width / 56
            context.scaleBy(x: scale, y: scale)
            switch kind {
            case .nightshadeNav: drawNightshadeNav(&context)
            case .concreteJungle: drawConcreteJungle(&context)
            case .mycologist: drawMycologist(&context)
            case .sunWalker: drawSunWalker(&context)
            }
        }
    }

    private func drawNightshadeNav(_ context: inout GraphicsContext) {
        context.fill(Path(CGRect(x: 0, y: 0, width: 56, height: 56)), with: .color(Color(hex: 0x3A0F3D)))
        let center = CGPoint(x: 28, y: 30)
        var petal = Path()
        petal.move(to: CGPoint(x: 0, y: -16))
        petal.addCurve(to: CGPoint(x: 0, y: 4), control1: CGPoint(x: 6, y: -10), control2: CGPoint(x: 6, y: -2))
        petal.addCurve(to: CGPoint(x: 0, y: -16), control1: CGPoint(x: -6, y: -2), control2: CGPoint(x: -6, y: -10))
        petal.closeSubpath()
        for i in 0..<5 {
            let angle = Angle.degrees(Double(i) * 72)
            var transform = CGAffineTransform(translationX: center.x, y: center.y)
            transform = transform.rotated(by: angle.radians)
            context.fill(petal.applying(transform), with: .color(Color(hex: 0xAD009B)))
        }
        context.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)), with: .color(Color(hex: 0xFFC7ED)))
    }

    private func drawConcreteJungle(_ context: inout GraphicsContext) {
        context.fill(Path(CGRect(x: 0, y: 0, width: 56, height: 56)), with: .color(Color(hex: 0xB7BEC0)))
        var skyline = Path()
        skyline.move(to: CGPoint(x: 0, y: 42))
        skyline.addLine(to: CGPoint(x: 18, y: 35))
        skyline.addLine(to: CGPoint(x: 14, y: 46))
        skyline.addLine(to: CGPoint(x: 32, y: 39))
        skyline.addLine(to: CGPoint(x: 28, y: 52))
        skyline.addLine(to: CGPoint(x: 56, y: 44))
        context.stroke(skyline, with: .color(Color(hex: 0x0D1117)), lineWidth: 2)

        var stem = Path()
        stem.move(to: CGPoint(x: 28, y: 42))
        stem.addCurve(to: CGPoint(x: 30, y: 15), control1: CGPoint(x: 28, y: 30), control2: CGPoint(x: 24, y: 24))
        context.stroke(stem, with: .color(Color(hex: 0x006D3F)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        var leaf1 = Path()
        leaf1.move(to: CGPoint(x: 28, y: 27))
        leaf1.addCurve(to: CGPoint(x: 18, y: 27), control1: CGPoint(x: 24, y: 23), control2: CGPoint(x: 20, y: 23))
        context.stroke(leaf1, with: .color(Color(hex: 0x2AF598)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        var leaf2 = Path()
        leaf2.move(to: CGPoint(x: 30, y: 21))
        leaf2.addCurve(to: CGPoint(x: 40, y: 21), control1: CGPoint(x: 34, y: 17), control2: CGPoint(x: 38, y: 17))
        context.stroke(leaf2, with: .color(Color(hex: 0x2AF598)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    private func drawMycologist(_ context: inout GraphicsContext) {
        context.fill(Path(CGRect(x: 0, y: 0, width: 56, height: 56)), with: .color(Color(hex: 0xEFE6D0)))
        var cap = Path()
        cap.move(to: CGPoint(x: 17, y: 32))
        cap.addCurve(to: CGPoint(x: 39, y: 32), control1: CGPoint(x: 17, y: 19), control2: CGPoint(x: 39, y: 19))
        cap.closeSubpath()
        context.fill(cap, with: .color(Color(hex: 0xB02700)))

        for (cx, cy, r) in [(23.0, 26.0, 2.1), (31.0, 23.0, 1.7), (34.0, 29.0, 1.5)] {
            context.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .color(.white))
        }

        let stem = Path(CGRect(x: 24, y: 32, width: 8, height: 13))
        context.fill(stem, with: .color(Color(hex: 0xF1E4C8)))
        context.stroke(stem, with: .color(Color(hex: 0x0D1117)), lineWidth: 1.5)
    }

    private func drawSunWalker(_ context: inout GraphicsContext) {
        context.fill(Path(CGRect(x: 0, y: 0, width: 56, height: 56)), with: .color(Color(hex: 0xF5C453)))
        let sun = Path(ellipseIn: CGRect(x: 20, y: 11, width: 16, height: 16))
        context.fill(sun, with: .color(.white))
        context.stroke(sun, with: .color(Color(hex: 0x0D1117)), lineWidth: 2)

        var rays = Path()
        rays.move(to: CGPoint(x: 28, y: 3)); rays.addLine(to: CGPoint(x: 28, y: 7))
        rays.move(to: CGPoint(x: 14, y: 19)); rays.addLine(to: CGPoint(x: 10, y: 19))
        rays.move(to: CGPoint(x: 42, y: 19)); rays.addLine(to: CGPoint(x: 46, y: 19))
        rays.move(to: CGPoint(x: 17, y: 9)); rays.addLine(to: CGPoint(x: 14, y: 6))
        rays.move(to: CGPoint(x: 39, y: 9)); rays.addLine(to: CGPoint(x: 42, y: 6))
        context.stroke(rays, with: .color(Color(hex: 0x0D1117)), lineWidth: 2)

        var cactus = Path()
        cactus.move(to: CGPoint(x: 28, y: 30)); cactus.addLine(to: CGPoint(x: 28, y: 50))
        context.stroke(cactus, with: .color(Color(hex: 0x006D3F)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        var arm1 = Path()
        arm1.move(to: CGPoint(x: 28, y: 35))
        arm1.addCurve(to: CGPoint(x: 22, y: 38), control1: CGPoint(x: 24, y: 35), control2: CGPoint(x: 22, y: 38))
        context.stroke(arm1, with: .color(Color(hex: 0x006D3F)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        var arm2 = Path()
        arm2.move(to: CGPoint(x: 28, y: 40))
        arm2.addCurve(to: CGPoint(x: 34, y: 43), control1: CGPoint(x: 32, y: 40), control2: CGPoint(x: 34, y: 43))
        context.stroke(arm2, with: .color(Color(hex: 0x006D3F)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }
}

struct DruidNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        DruidNeoBrutalistView()
            .environmentObject(RedesignPrototypeState())
    }
}
