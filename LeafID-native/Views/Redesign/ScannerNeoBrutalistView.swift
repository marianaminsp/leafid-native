//
//  ScannerNeoBrutalistView.swift
//  LeafID-native
//
//  Third redesign screen — a 1:1 SwiftUI build of stitch_botanical_explorer/identify/code.html
//  (the full-screen camera/scanner state). Background photo is the mockup's own placeholder,
//  not a live camera feed — camera capture stays whatever it is on the current shipped screen
//  until this gets wired up for real (out of scope for the visual pilot).
//

import SwiftUI

struct ScannerNeoBrutalistView: View {
    var onClose: () -> Void = {}
    var onSelectTab: (NeoBrutalistTab) -> Void = { _ in }

    @State private var missingFeature: String?
    @State private var flashOn = false
    @State private var isFrontCamera = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ZStack {
                GeometryReader { geo in
                    Image("IdentifyHeroPlaceholder")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                Color.black.opacity(0.15)

                VStack {
                    HStack(alignment: .top) {
                        aiActiveBadge
                        Spacer()
                        flashButton
                    }
                    .padding(.top, NeoBrutalistSpacing.sm)

                    Spacer()

                    reticle

                    Spacer()

                    controlRow
                        .padding(.bottom, NeoBrutalistSpacing.xl)
                }
                .padding(.horizontal, NeoBrutalistSpacing.md)
            }
            .clipped()
            .frame(maxHeight: .infinity)

            NeoBrutalistTabBar(activeTab: .identify, onSelect: { tab in
                onClose()
                onSelectTab(tab)
            })
        }
        .background(NeoBrutalistColor.surface.ignoresSafeArea())
        .missingScreenAlert($missingFeature)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: NeoBrutalistSpacing.sm) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NeoBrutalistColor.onSurface)
            }
            .buttonStyle(.plain)
            .padding(.trailing, NeoBrutalistSpacing.xs)

            Text("IDENTIFY")
                .font(NeoBrutalistFont.headlineMd())
                .foregroundStyle(NeoBrutalistColor.onSurface)

            Spacer()

            Button(action: { onSelectTab(.druid); onClose() }) {
                ZStack {
                    Circle().fill(NeoBrutalistColor.primary)
                    Image(systemName: "person.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(NeoBrutalistColor.onPrimary)
                }
                .frame(width: 36, height: 36)
                .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NeoBrutalistSpacing.md)
        .padding(.vertical, NeoBrutalistSpacing.sm)
        .background(NeoBrutalistColor.surface.opacity(0.94))
    }

    // MARK: - Overlay chrome

    private var aiActiveBadge: some View {
        HStack(spacing: NeoBrutalistSpacing.xs) {
            Circle()
                .fill(NeoBrutalistColor.primaryContainer)
                .frame(width: 8, height: 8)
            Text("BOTANIST AI ACTIVE")
                .font(.custom("SpaceMono-Bold", size: 11))
                .kerning(1.2)
                .foregroundStyle(NeoBrutalistColor.onPrimary)
        }
        .padding(.horizontal, NeoBrutalistSpacing.sm)
        .padding(.vertical, NeoBrutalistSpacing.xs)
        .background(NeoBrutalistColor.primary.opacity(0.9))
        .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
    }

    private var flashButton: some View {
        Button(action: { flashOn.toggle() }) {
            Image(systemName: flashOn ? "bolt.fill" : "bolt.slash.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(flashOn ? NeoBrutalistColor.onPrimary : NeoBrutalistColor.onSurface)
                .frame(width: 36, height: 36)
                .background(flashOn ? NeoBrutalistColor.primary : NeoBrutalistColor.surface.opacity(0.9))
                .neoBrutalistSurface(borderWidth: NeoBrutalistStroke.default, shadowOffset: 4)
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 4))
    }

    private var reticle: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { corner in
                ReticleBracket()
                    .stroke(NeoBrutalistColor.primaryContainer, lineWidth: 4)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(Double(corner) * 90))
                    .offset(
                        x: (corner == 1 || corner == 2) ? 110 : -110,
                        y: (corner == 2 || corner == 3) ? 110 : -110
                    )
            }
        }
        .frame(width: 252, height: 252)
    }

    // MARK: - Controls

    private var controlRow: some View {
        HStack(spacing: NeoBrutalistSpacing.lg) {
            circleControl(systemImage: "photo.on.rectangle", size: 48) {
                missingFeature = "Photo Library Picker"
            }

            Button(action: { missingFeature = "Scan Result" }) {
                ZStack {
                    Circle()
                        .fill(NeoBrutalistColor.primaryContainer)
                        .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.heavy))
                    Circle()
                        .fill(NeoBrutalistColor.primary)
                        .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
                        .frame(width: 60, height: 60)
                }
                .frame(width: 76, height: 76)
            }
            .buttonStyle(.plain)

            circleControl(systemImage: isFrontCamera ? "camera.rotate.fill" : "arrow.triangle.2.circlepath.camera", size: 48) {
                isFrontCamera.toggle()
            }
        }
    }

    private func circleControl(systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NeoBrutalistColor.onSurface)
                .frame(width: size, height: size)
                .background(Circle().fill(NeoBrutalistColor.surface.opacity(0.9)))
                .overlay(Circle().strokeBorder(NeoBrutalistColor.ink, lineWidth: NeoBrutalistStroke.default))
        }
        .buttonStyle(NeoBrutalistPressableStyle(shadowOffset: 2))
    }
}

/// One right-angle corner bracket of the scanner reticle; rotated per corner in `reticle`.
private struct ReticleBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

struct ScannerNeoBrutalistView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerNeoBrutalistView()
    }
}
