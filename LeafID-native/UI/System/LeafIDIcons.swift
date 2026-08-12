//
//  LeafIDIcons.swift
//  LeafID-native
//
//  Brand-specific glyph family following SF Symbols conventions (stroke-based silhouette,
//  hierarchical secondary detail, weight-driven line width) as a botanical alternative to
//  generic SF Symbols (`leaf`, `leaf.fill`, `tree`, etc.) — library only, not wired into any
//  live screen yet. See `UI/Gallery/DesignSystemGalleryView.swift` for the full showcase.
//

import SwiftUI

/// Path builders live on a shared 100×100 design grid (y-down) so every glyph scales like an SF Symbol.
private enum LeafIDGlyphPaths {
    static func pt(_ rect: CGRect, _ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + x / 100 * rect.width, y: rect.minY + y / 100 * rect.height)
    }

    static func mapleLeaf(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(50, 6))
        path.addQuadCurve(to: pt(60, 26), control: pt(53, 15))
        path.addQuadCurve(to: pt(88, 30), control: pt(74, 16))
        path.addQuadCurve(to: pt(66, 48), control: pt(78, 42))
        path.addQuadCurve(to: pt(80, 72), control: pt(88, 58))
        path.addQuadCurve(to: pt(56, 70), control: pt(68, 80))
        path.addLine(to: pt(50, 94))
        path.addLine(to: pt(44, 70))
        path.addQuadCurve(to: pt(20, 72), control: pt(32, 80))
        path.addQuadCurve(to: pt(34, 48), control: pt(12, 58))
        path.addQuadCurve(to: pt(12, 30), control: pt(22, 42))
        path.addQuadCurve(to: pt(40, 26), control: pt(26, 16))
        path.addQuadCurve(to: pt(50, 6), control: pt(47, 15))
        path.closeSubpath()
        return path
    }

    static func mapleVein(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(50, 18))
        path.addLine(to: pt(50, 88))
        path.move(to: pt(50, 36))
        path.addLine(to: pt(76, 30))
        path.move(to: pt(50, 36))
        path.addLine(to: pt(24, 30))
        path.move(to: pt(50, 56))
        path.addLine(to: pt(70, 64))
        path.move(to: pt(50, 56))
        path.addLine(to: pt(30, 64))
        return path
    }

    static func oakLeaf(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(50, 8))
        path.addCurve(to: pt(50, 60), control1: pt(90, 24), control2: pt(84, 46))
        path.addCurve(to: pt(50, 96), control1: pt(66, 72), control2: pt(58, 86))
        path.addCurve(to: pt(50, 60), control1: pt(42, 86), control2: pt(34, 72))
        path.addCurve(to: pt(50, 8), control1: pt(16, 46), control2: pt(10, 24))
        path.closeSubpath()
        return path
    }

    static func oakVein(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(50, 14))
        path.addLine(to: pt(50, 88))
        return path
    }

    static func acorn(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        // nut
        path.move(to: pt(28, 46))
        path.addCurve(to: pt(50, 93), control1: pt(23, 68), control2: pt(35, 90))
        path.addCurve(to: pt(72, 46), control1: pt(65, 90), control2: pt(77, 68))
        path.addCurve(to: pt(28, 46), control1: pt(66, 34), control2: pt(34, 34))
        path.closeSubpath()
        // cap
        path.move(to: pt(20, 44))
        path.addCurve(to: pt(50, 18), control1: pt(22, 26), control2: pt(35, 18))
        path.addCurve(to: pt(80, 44), control1: pt(65, 18), control2: pt(78, 26))
        path.addCurve(to: pt(20, 44), control1: pt(66, 52), control2: pt(34, 52))
        path.closeSubpath()
        // stem
        path.move(to: pt(50, 18))
        path.addCurve(to: pt(54, 7), control1: pt(50, 13), control2: pt(52, 9))
        path.addCurve(to: pt(50, 18), control1: pt(52, 10), control2: pt(50, 14))
        path.closeSubpath()
        return path
    }

    static func acornVein(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(28, 34)); path.addLine(to: pt(72, 34))
        path.move(to: pt(24, 40)); path.addLine(to: pt(76, 40))
        return path
    }

    static func pinecone(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(50, 10))
        path.addCurve(to: pt(50, 94), control1: pt(86, 30), control2: pt(78, 76))
        path.addCurve(to: pt(50, 10), control1: pt(22, 76), control2: pt(14, 30))
        path.closeSubpath()
        return path
    }

    static func pineconeVein(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(30, 30)); path.addLine(to: pt(70, 30))
        path.move(to: pt(24, 46)); path.addLine(to: pt(76, 46))
        path.move(to: pt(26, 62)); path.addLine(to: pt(74, 62))
        path.move(to: pt(33, 78)); path.addLine(to: pt(67, 78))
        return path
    }

    static func berry(_ rect: CGRect) -> Path {
        var path = Path()
        func r(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGRect {
            CGRect(
                x: rect.minX + x0 / 100 * rect.width, y: rect.minY + y0 / 100 * rect.height,
                width: (x1 - x0) / 100 * rect.width, height: (y1 - y0) / 100 * rect.height
            )
        }
        path.addEllipse(in: r(18, 52, 46, 80))
        path.addEllipse(in: r(54, 52, 82, 80))
        path.addEllipse(in: r(36, 30, 64, 58))
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(48, 22))
        path.addCurve(to: pt(64, 6), control1: pt(50, 14), control2: pt(56, 10))
        path.addCurve(to: pt(52, 26), control1: pt(58, 14), control2: pt(54, 20))
        path.closeSubpath()
        return path
    }

    static func flower(_ rect: CGRect) -> Path {
        var path = Path()
        let pivot = CGPoint(x: rect.minX + rect.width / 2, y: rect.minY + rect.height / 2)
        func petalPath() -> Path {
            var p = Path()
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
            p.move(to: pt(50, 50))
            p.addCurve(to: pt(50, 10), control1: pt(38, 42), control2: pt(38, 16))
            p.addCurve(to: pt(50, 50), control1: pt(62, 16), control2: pt(62, 42))
            p.closeSubpath()
            return p
        }
        for i in 0 ..< 5 {
            let angle = CGFloat(i) * (2 * .pi / 5)
            let transform = CGAffineTransform(translationX: pivot.x, y: pivot.y)
                .rotated(by: angle)
                .translatedBy(x: -pivot.x, y: -pivot.y)
            path.addPath(petalPath().applying(transform))
        }
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        let center = pt(40, 40)
        let edge = pt(60, 60)
        path.addEllipse(in: CGRect(x: center.x, y: center.y, width: edge.x - center.x, height: edge.y - center.y))
        return path
    }

    static func tree(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        // canopy: scalloped blob
        path.move(to: pt(50, 8))
        path.addCurve(to: pt(84, 30), control1: pt(66, 8), control2: pt(80, 16))
        path.addCurve(to: pt(90, 54), control1: pt(92, 36), control2: pt(94, 46))
        path.addCurve(to: pt(68, 68), control1: pt(88, 62), control2: pt(80, 68))
        path.addCurve(to: pt(50, 62), control1: pt(60, 68), control2: pt(54, 66))
        path.addCurve(to: pt(32, 68), control1: pt(46, 66), control2: pt(40, 68))
        path.addCurve(to: pt(10, 54), control1: pt(20, 68), control2: pt(12, 62))
        path.addCurve(to: pt(16, 30), control1: pt(6, 46), control2: pt(8, 36))
        path.addCurve(to: pt(50, 8), control1: pt(20, 16), control2: pt(34, 8))
        path.closeSubpath()
        // trunk
        path.move(to: pt(44, 60))
        path.addLine(to: pt(41, 94))
        path.addLine(to: pt(59, 94))
        path.addLine(to: pt(56, 60))
        path.closeSubpath()
        return path
    }

    static func sprout(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        // stem: thin tapered blade, base to crown
        path.move(to: pt(48, 96))
        path.addCurve(to: pt(50, 46), control1: pt(47, 74), control2: pt(48, 58))
        path.addCurve(to: pt(52, 96), control1: pt(52, 58), control2: pt(53, 74))
        path.closeSubpath()
        // crown leaflet (top, pointing straight up)
        path.move(to: pt(50, 16))
        path.addCurve(to: pt(50, 48), control1: pt(66, 24), control2: pt(62, 40))
        path.addCurve(to: pt(50, 16), control1: pt(38, 40), control2: pt(34, 24))
        path.closeSubpath()
        // left leaflet
        path.move(to: pt(48, 66))
        path.addCurve(to: pt(16, 50), control1: pt(32, 68), control2: pt(20, 62))
        path.addCurve(to: pt(48, 66), control1: pt(18, 40), control2: pt(36, 56))
        path.closeSubpath()
        // right leaflet (mirror)
        path.move(to: pt(52, 66))
        path.addCurve(to: pt(84, 50), control1: pt(68, 68), control2: pt(80, 62))
        path.addCurve(to: pt(52, 66), control1: pt(82, 40), control2: pt(64, 56))
        path.closeSubpath()
        return path
    }
    // MARK: - Traced from reference art (potrace, see docs/audit or session scratch)

    static func leafSpray1(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(87.8, 5.63))
        path.addCurve(to: pt(61.93, 49.05), control1: pt(73.73, 14.21), control2: pt(64.2, 30.16))
        path.addLine(to: pt(61.13, 55.71))
        path.addLine(to: pt(62.0, 62.78))
        path.addCurve(to: pt(64.07, 74.76), control1: pt(62.4, 66.67), control2: pt(63.33, 72.06))
        path.addCurve(to: pt(64.47, 89.05), control1: pt(65.53, 80.56), control2: pt(65.67, 84.92))
        path.addCurve(to: pt(62.07, 85.16), control1: pt(63.13, 93.65), control2: pt(62.93, 93.41))
        path.addCurve(to: pt(59.73, 75.4), control1: pt(61.07, 76.43), control2: pt(60.87, 75.4))
        path.addLine(to: pt(58.87, 75.4))
        path.addLine(to: pt(58.0, 80.87))
        path.addLine(to: pt(57.13, 86.27))
        path.addLine(to: pt(58.0, 90.4))
        path.addCurve(to: pt(58.4, 95.0), control1: pt(58.47, 92.7), control2: pt(58.6, 94.76))
        path.addCurve(to: pt(55.13, 87.62), control1: pt(57.67, 95.95), control2: pt(56.2, 92.62))
        path.addLine(to: pt(54.13, 82.7))
        path.addLine(to: pt(55.2, 72.7))
        path.addLine(to: pt(56.27, 62.78))
        path.addLine(to: pt(55.4, 54.68))
        path.addCurve(to: pt(38.47, 17.22), control1: pt(53.53, 36.59), control2: pt(48.73, 25.87))
        path.addCurve(to: pt(23.67, 7.78), control1: pt(34.0, 13.41), control2: pt(25.87, 8.25))
        path.addLine(to: pt(22.33, 7.54))
        path.addLine(to: pt(22.53, 17.46))
        path.addCurve(to: pt(27.27, 54.6), control1: pt(22.87, 35.56), control2: pt(24.07, 45.0))
        path.addCurve(to: pt(27.2, 58.41), control1: pt(29.0, 59.76), control2: pt(29.0, 59.84))
        path.addCurve(to: pt(19.93, 56.27), control1: pt(26.33, 57.78), control2: pt(23.07, 56.83))
        path.addLine(to: pt(14.2, 55.24))
        path.addLine(to: pt(8.4, 56.27))
        path.addLine(to: pt(2.67, 57.3))
        path.addLine(to: pt(2.67, 58.65))
        path.addCurve(to: pt(5.13, 62.14), control1: pt(2.73, 59.37), control2: pt(3.8, 60.87))
        path.addCurve(to: pt(15.33, 78.57), control1: pt(8.4, 65.0), control2: pt(12.27, 71.27))
        path.addCurve(to: pt(34.4, 98.41), control1: pt(19.87, 89.21), control2: pt(25.6, 95.16))
        path.addCurve(to: pt(43.67, 102.06), control1: pt(36.93, 99.37), control2: pt(41.07, 101.03))
        path.addLine(to: pt(48.27, 103.97))
        path.addLine(to: pt(50.53, 106.59))
        path.addCurve(to: pt(54.47, 113.49), control1: pt(51.73, 107.94), control2: pt(53.53, 111.11))
        path.addLine(to: pt(56.13, 117.86))
        path.addLine(to: pt(55.73, 123.65))
        path.addLine(to: pt(55.33, 129.44))
        path.addLine(to: pt(56.27, 129.84))
        path.addCurve(to: pt(58.47, 129.52), control1: pt(56.8, 130.08), control2: pt(57.8, 129.92))
        path.addLine(to: pt(59.67, 128.73))
        path.addLine(to: pt(60.53, 123.41))
        path.addLine(to: pt(61.4, 118.1))
        path.addLine(to: pt(63.33, 114.68))
        path.addCurve(to: pt(68.27, 108.17), control1: pt(64.4, 112.78), control2: pt(66.67, 109.84))
        path.addLine(to: pt(71.27, 105.0))
        path.addLine(to: pt(77.13, 104.05))
        path.addCurve(to: pt(98.27, 99.44), control1: pt(86.47, 102.54), control2: pt(91.2, 101.51))
        path.addCurve(to: pt(117.73, 85.56), control1: pt(108.93, 96.43), control2: pt(111.73, 94.37))
        path.addCurve(to: pt(126.2, 74.6), control1: pt(119.8, 82.46), control2: pt(123.6, 77.54))
        path.addLine(to: pt(130.87, 69.13))
        path.addLine(to: pt(130.47, 68.02))
        path.addLine(to: pt(130.13, 66.9))
        path.addLine(to: pt(124.87, 65.24))
        path.addCurve(to: pt(93.6, 67.94), control1: pt(113.13, 61.59), control2: pt(103.13, 62.46))
        path.addLine(to: pt(89.67, 70.16))
        path.addLine(to: pt(82.93, 78.1))
        path.addLine(to: pt(76.2, 86.11))
        path.addLine(to: pt(72.4, 95.16))
        path.addLine(to: pt(68.53, 104.21))
        path.addLine(to: pt(65.87, 107.7))
        path.addCurve(to: pt(62.27, 111.11), control1: pt(64.33, 109.52), control2: pt(62.73, 111.11))
        path.addLine(to: pt(61.4, 111.11))
        path.addLine(to: pt(61.8, 108.49))
        path.addCurve(to: pt(68.2, 86.19), control1: pt(62.47, 104.13), control2: pt(66.73, 89.44))
        path.addLine(to: pt(69.67, 83.1))
        path.addLine(to: pt(77.4, 75.79))
        path.addLine(to: pt(85.07, 68.49))
        path.addLine(to: pt(88.13, 63.65))
        path.addCurve(to: pt(97.33, 29.37), control1: pt(93.67, 54.92), control2: pt(97.33, 41.19))
        path.addCurve(to: pt(92.33, 3.65), control1: pt(97.33, 20.79), control2: pt(94.2, 4.52))
        path.addCurve(to: pt(87.8, 5.63), control1: pt(91.93, 3.49), control2: pt(89.87, 4.37))
        path.closeSubpath()
        path.move(to: pt(30.27, 61.59))
        path.addLine(to: pt(30.67, 62.78))
        path.addLine(to: pt(30.0, 62.3))
        path.addCurve(to: pt(29.33, 61.03), control1: pt(29.6, 62.06), control2: pt(29.33, 61.51))
        path.addCurve(to: pt(30.27, 61.59), control1: pt(29.33, 59.92), control2: pt(29.8, 60.16))
        path.closeSubpath()
        path.move(to: pt(44.0, 78.57))
        path.addCurve(to: pt(47.27, 81.35), control1: pt(44.2, 78.81), control2: pt(45.67, 80.0))
        path.addCurve(to: pt(53.53, 90.08), control1: pt(50.33, 83.81), control2: pt(52.93, 87.46))
        path.addCurve(to: pt(55.6, 97.22), control1: pt(53.73, 90.95), control2: pt(54.67, 94.13))
        path.addLine(to: pt(57.33, 102.78))
        path.addLine(to: pt(57.33, 107.3))
        path.addCurve(to: pt(56.87, 111.9), control1: pt(57.33, 109.84), control2: pt(57.13, 111.9))
        path.addCurve(to: pt(53.73, 107.14), control1: pt(56.53, 111.9), control2: pt(55.2, 109.76))
        path.addLine(to: pt(51.2, 102.38))
        path.addLine(to: pt(50.0, 96.27))
        path.addCurve(to: pt(47.67, 86.35), control1: pt(49.33, 92.86), control2: pt(48.27, 88.41))
        path.addLine(to: pt(46.53, 82.62))
        path.addLine(to: pt(43.93, 79.76))
        path.addCurve(to: pt(41.33, 76.51), control1: pt(42.53, 78.25), control2: pt(41.33, 76.75))
        path.addCurve(to: pt(44.0, 78.57), control1: pt(41.33, 76.03), control2: pt(43.0, 77.38))
        path.closeSubpath()
        return path
    }

    static func leafSpray2(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(65.11, 7.04))
        path.addCurve(to: pt(44.59, 42.47), control1: pt(51.95, 19.55), control2: pt(47.01, 28.01))
        path.addLine(to: pt(43.55, 49.06))
        path.addLine(to: pt(43.38, 45.92))
        path.addLine(to: pt(43.29, 42.77))
        path.addLine(to: pt(40.52, 40.07))
        path.addCurve(to: pt(5.11, 24.87), control1: pt(32.73, 32.36), control2: pt(10.82, 23.0))
        path.addLine(to: pt(3.9, 25.24))
        path.addLine(to: pt(4.42, 38.05))
        path.addCurve(to: pt(45.45, 98.5), control1: pt(5.8, 69.74), control2: pt(16.28, 85.17))
        path.addCurve(to: pt(55.15, 103.52), control1: pt(49.78, 100.45), control2: pt(54.11, 102.7))
        path.addCurve(to: pt(61.9, 114.16), control1: pt(57.06, 105.02), control2: pt(57.4, 105.69))
        path.addLine(to: pt(64.16, 118.58))
        path.addLine(to: pt(64.76, 124.27))
        path.addLine(to: pt(65.37, 129.96))
        path.addLine(to: pt(67.36, 130.19))
        path.addCurve(to: pt(70.48, 129.59), control1: pt(68.48, 130.34), control2: pt(69.87, 130.11))
        path.addLine(to: pt(71.69, 128.76))
        path.addLine(to: pt(72.03, 124.12))
        path.addLine(to: pt(72.47, 119.48))
        path.addLine(to: pt(74.81, 114.98))
        path.addCurve(to: pt(78.61, 108.01), control1: pt(76.19, 112.51), control2: pt(77.84, 109.36))
        path.addCurve(to: pt(93.33, 98.43), control1: pt(80.0, 105.39), control2: pt(81.39, 104.49))
        path.addCurve(to: pt(126.32, 63.07), control1: pt(111.0, 89.51), control2: pt(121.39, 78.35))
        path.addCurve(to: pt(129.7, 29.96), control1: pt(128.4, 56.4), control2: pt(130.13, 40.3))
        path.addLine(to: pt(129.44, 22.1))
        path.addLine(to: pt(127.27, 22.25))
        path.addCurve(to: pt(110.82, 27.12), control1: pt(123.12, 22.47), control2: pt(118.1, 23.9))
        path.addLine(to: pt(103.46, 30.34))
        path.addLine(to: pt(97.75, 35.21))
        path.addLine(to: pt(91.95, 40.07))
        path.addLine(to: pt(91.43, 47.94))
        path.addCurve(to: pt(89.09, 63.22), control1: pt(90.82, 57.68), control2: pt(90.13, 62.32))
        path.addCurve(to: pt(88.31, 65.32), control1: pt(88.66, 63.67), control2: pt(88.31, 64.57))
        path.addCurve(to: pt(87.53, 68.01), control1: pt(88.31, 66.07), control2: pt(87.97, 67.27))
        path.addCurve(to: pt(83.9, 74.53), control1: pt(87.1, 68.69), control2: pt(85.45, 71.61))
        path.addCurve(to: pt(80.35, 80.0), control1: pt(82.34, 77.38), control2: pt(80.69, 79.85))
        path.addCurve(to: pt(79.65, 81.12), control1: pt(80.0, 80.15), control2: pt(79.65, 80.67))
        path.addCurve(to: pt(77.49, 84.19), control1: pt(79.65, 81.65), control2: pt(78.7, 83.0))
        path.addCurve(to: pt(75.24, 94.76), control1: pt(74.46, 87.19), control2: pt(74.03, 89.29))
        path.addCurve(to: pt(76.19, 102.1), control1: pt(75.76, 97.3), control2: pt(76.19, 100.67))
        path.addLine(to: pt(76.19, 104.79))
        path.addLine(to: pt(73.85, 109.14))
        path.addLine(to: pt(71.43, 113.48))
        path.addLine(to: pt(71.17, 104.87))
        path.addLine(to: pt(71.0, 96.25))
        path.addLine(to: pt(70.04, 94.68))
        path.addLine(to: pt(69.09, 93.11))
        path.addLine(to: pt(70.48, 90.79))
        path.addCurve(to: pt(72.99, 87.49), control1: pt(71.17, 89.59), control2: pt(72.29, 88.09))
        path.addCurve(to: pt(89.18, 57.53), control1: pt(78.61, 82.55), control2: pt(86.58, 67.87))
        path.addLine(to: pt(90.3, 53.33))
        path.addLine(to: pt(89.78, 45.92))
        path.addCurve(to: pt(79.13, 15.88), control1: pt(89.09, 35.43), control2: pt(87.36, 30.56))
        path.addLine(to: pt(71.77, 3.0))
        path.addLine(to: pt(70.65, 3.0))
        path.addCurve(to: pt(65.11, 7.04), control1: pt(69.96, 3.0), control2: pt(67.53, 4.79))
        path.closeSubpath()
        path.move(to: pt(67.45, 74.91))
        path.addLine(to: pt(67.53, 90.26))
        path.addLine(to: pt(66.67, 89.14))
        path.addLine(to: pt(65.8, 88.01))
        path.addLine(to: pt(65.89, 72.28))
        path.addLine(to: pt(65.89, 56.55))
        path.addLine(to: pt(66.67, 58.05))
        path.addCurve(to: pt(67.45, 74.91), control1: pt(67.1, 58.88), control2: pt(67.45, 66.44))
        path.closeSubpath()
        path.move(to: pt(55.84, 81.42))
        path.addCurve(to: pt(62.94, 88.99), control1: pt(57.66, 83.82), control2: pt(60.87, 87.27))
        path.addLine(to: pt(66.67, 92.28))
        path.addLine(to: pt(65.8, 98.35))
        path.addCurve(to: pt(64.94, 107.72), control1: pt(65.37, 101.72), control2: pt(64.94, 105.92))
        path.addLine(to: pt(64.94, 111.01))
        path.addLine(to: pt(63.98, 110.71))
        path.addCurve(to: pt(60.95, 105.99), control1: pt(63.46, 110.56), control2: pt(62.08, 108.46))
        path.addLine(to: pt(58.87, 101.65))
        path.addLine(to: pt(58.87, 94.23))
        path.addLine(to: pt(58.87, 86.82))
        path.addLine(to: pt(55.41, 82.4))
        path.addCurve(to: pt(52.29, 77.15), control1: pt(52.21, 78.28), control2: pt(51.52, 77.15))
        path.addCurve(to: pt(55.84, 81.42), control1: pt(52.47, 77.15), control2: pt(54.03, 79.1))
        path.closeSubpath()
        return path
    }

    static func leafSpray3(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(36.42, 5.36))
        path.addCurve(to: pt(34.15, 15.38), control1: pt(36.04, 6.55), control2: pt(35.03, 11.05))
        path.addLine(to: pt(32.58, 23.27))
        path.addLine(to: pt(32.45, 32.5))
        path.addCurve(to: pt(32.01, 41.81), control1: pt(32.45, 37.63), control2: pt(32.2, 41.81))
        path.addCurve(to: pt(27.92, 39.76), control1: pt(31.76, 41.81), control2: pt(29.94, 40.87))
        path.addCurve(to: pt(19.5, 36.21), control1: pt(25.91, 38.66), control2: pt(22.14, 37.08))
        path.addLine(to: pt(14.78, 34.71))
        path.addLine(to: pt(8.68, 34.71))
        path.addLine(to: pt(2.52, 34.71))
        path.addLine(to: pt(2.52, 35.5))
        path.addCurve(to: pt(4.97, 40.95), control1: pt(2.52, 35.9), control2: pt(3.58, 38.34))
        path.addCurve(to: pt(10.69, 56.02), control1: pt(6.29, 43.55), control2: pt(8.87, 50.34))
        path.addCurve(to: pt(24.59, 81.03), control1: pt(15.41, 70.85), control2: pt(17.86, 75.27))
        path.addCurve(to: pt(36.04, 89.39), control1: pt(27.17, 83.31), control2: pt(28.81, 84.5))
        path.addCurve(to: pt(45.85, 95.07), control1: pt(37.48, 90.41), control2: pt(41.89, 92.94))
        path.addLine(to: pt(53.02, 98.93))
        path.addLine(to: pt(54.53, 100.91))
        path.addCurve(to: pt(58.93, 109.19), control1: pt(55.35, 102.09), control2: pt(57.36, 105.8))
        path.addLine(to: pt(61.89, 115.42))
        path.addLine(to: pt(62.14, 122.21))
        path.addLine(to: pt(62.45, 128.99))
        path.addLine(to: pt(63.14, 129.55))
        path.addCurve(to: pt(65.28, 130.18), control1: pt(63.52, 129.86), control2: pt(64.47, 130.18))
        path.addLine(to: pt(66.67, 130.18))
        path.addLine(to: pt(66.67, 125.21))
        path.addLine(to: pt(66.67, 120.16))
        path.addLine(to: pt(69.12, 115.5))
        path.addCurve(to: pt(84.72, 104.14), control1: pt(74.03, 105.96), control2: pt(74.97, 105.33))
        path.addCurve(to: pt(119.94, 78.5), control1: pt(102.39, 102.09), control2: pt(108.55, 97.51))
        path.addCurve(to: pt(128.36, 65.72), control1: pt(123.08, 73.29), control2: pt(126.86, 67.53))
        path.addLine(to: pt(131.07, 62.33))
        path.addLine(to: pt(130.44, 61.54))
        path.addCurve(to: pt(109.81, 57.91), control1: pt(128.62, 59.25), control2: pt(115.85, 56.96))
        path.addLine(to: pt(106.35, 58.46))
        path.addLine(to: pt(105.16, 60.2))
        path.addCurve(to: pt(95.79, 72.27), control1: pt(101.51, 65.4), control2: pt(95.97, 72.58))
        path.addCurve(to: pt(99.18, 67.38), control1: pt(95.66, 72.11), control2: pt(97.17, 69.9))
        path.addCurve(to: pt(108.87, 45.36), control1: pt(103.52, 61.78), control2: pt(106.04, 56.02))
        path.addCurve(to: pt(114.28, 29.35), control1: pt(110.06, 41.03), control2: pt(112.45, 33.77))
        path.addCurve(to: pt(117.61, 20.83), control1: pt(116.1, 24.85), control2: pt(117.61, 20.99))
        path.addCurve(to: pt(99.69, 24.06), control1: pt(117.61, 19.33), control2: pt(105.47, 21.54))
        path.addCurve(to: pt(73.65, 65.09), control1: pt(86.6, 29.74), control2: pt(77.3, 44.5))
        path.addCurve(to: pt(72.08, 78.26), control1: pt(73.27, 67.22), control2: pt(72.58, 73.21))
        path.addLine(to: pt(71.19, 87.5))
        path.addLine(to: pt(69.69, 91.2))
        path.addCurve(to: pt(67.48, 95.31), control1: pt(68.93, 93.25), control2: pt(67.86, 95.07))
        path.addLine(to: pt(66.67, 95.62))
        path.addLine(to: pt(66.67, 89.78))
        path.addLine(to: pt(66.67, 84.02))
        path.addLine(to: pt(68.3, 78.5))
        path.addCurve(to: pt(70.44, 70.61), control1: pt(69.18, 75.42), control2: pt(70.19, 71.87))
        path.addCurve(to: pt(72.14, 63.12), control1: pt(70.75, 69.27), control2: pt(71.51, 65.96))
        path.addLine(to: pt(73.27, 57.99))
        path.addLine(to: pt(73.14, 39.92))
        path.addLine(to: pt(73.02, 21.85))
        path.addLine(to: pt(72.39, 21.07))
        path.addLine(to: pt(71.82, 20.36))
        path.addLine(to: pt(69.25, 25.09))
        path.addCurve(to: pt(64.97, 34.4), control1: pt(67.86, 27.69), control2: pt(65.91, 31.87))
        path.addLine(to: pt(63.27, 39.05))
        path.addLine(to: pt(63.02, 37.08))
        path.addCurve(to: pt(40.0, 4.73), control1: pt(61.89, 26.51), control2: pt(50.31, 10.34))
        path.addLine(to: pt(37.04, 3.16))
        path.addLine(to: pt(36.42, 5.36))
        path.closeSubpath()
        path.move(to: pt(61.07, 51.05))
        path.addLine(to: pt(60.75, 54.04))
        path.addLine(to: pt(60.5, 52.23))
        path.addCurve(to: pt(61.19, 48.13), control1: pt(60.31, 50.49), control2: pt(60.69, 48.13))
        path.addCurve(to: pt(61.07, 51.05), control1: pt(61.26, 48.13), control2: pt(61.26, 49.47))
        path.closeSubpath()
        path.move(to: pt(43.08, 52.86))
        path.addCurve(to: pt(43.9, 54.44), control1: pt(43.71, 53.73), control2: pt(44.09, 54.44))
        path.addCurve(to: pt(42.45, 52.86), control1: pt(43.71, 54.44), control2: pt(43.08, 53.73))
        path.addCurve(to: pt(41.64, 51.28), control1: pt(41.82, 51.99), control2: pt(41.45, 51.28))
        path.addCurve(to: pt(43.08, 52.86), control1: pt(41.82, 51.28), control2: pt(42.45, 51.99))
        path.closeSubpath()
        path.move(to: pt(45.79, 56.88))
        path.addCurve(to: pt(45.03, 57.2), control1: pt(46.98, 59.25), control2: pt(46.29, 59.57))
        path.addCurve(to: pt(44.47, 55.23), control1: pt(44.47, 56.09), control2: pt(44.21, 55.23))
        path.addCurve(to: pt(45.79, 56.88), control1: pt(44.78, 55.23), control2: pt(45.35, 55.94))
        path.closeSubpath()
        path.move(to: pt(48.05, 61.3))
        path.addCurve(to: pt(48.81, 63.67), control1: pt(48.24, 62.09), control2: pt(48.62, 63.2))
        path.addCurve(to: pt(48.55, 64.69), control1: pt(48.99, 64.22), control2: pt(48.87, 64.69))
        path.addCurve(to: pt(47.55, 63.27), control1: pt(48.24, 64.69), control2: pt(47.8, 64.06))
        path.addCurve(to: pt(46.79, 60.91), control1: pt(47.36, 62.56), control2: pt(46.98, 61.46))
        path.addCurve(to: pt(47.04, 59.96), control1: pt(46.6, 60.43), control2: pt(46.73, 59.96))
        path.addCurve(to: pt(48.05, 61.3), control1: pt(47.36, 59.96), control2: pt(47.8, 60.59))
        path.closeSubpath()
        path.move(to: pt(50.31, 67.93))
        path.addCurve(to: pt(49.69, 68.24), control1: pt(50.31, 68.4), control2: pt(50.06, 68.48))
        path.addCurve(to: pt(49.06, 66.98), control1: pt(49.37, 68.01), control2: pt(49.06, 67.38))
        path.addCurve(to: pt(49.69, 66.67), control1: pt(49.06, 66.51), control2: pt(49.37, 66.43))
        path.addCurve(to: pt(50.31, 67.93), control1: pt(50.06, 66.9), control2: pt(50.31, 67.53))
        path.closeSubpath()
        path.move(to: pt(61.64, 71.4))
        path.addLine(to: pt(61.64, 72.98))
        path.addLine(to: pt(61.01, 71.79))
        path.addCurve(to: pt(60.38, 69.03), control1: pt(60.69, 71.16), control2: pt(60.38, 69.9))
        path.addLine(to: pt(60.38, 67.46))
        path.addLine(to: pt(61.01, 68.64))
        path.addCurve(to: pt(61.64, 71.4), control1: pt(61.32, 69.27), control2: pt(61.64, 70.53))
        path.closeSubpath()
        path.move(to: pt(51.57, 72.03))
        path.addCurve(to: pt(50.94, 72.19), control1: pt(51.57, 72.43), control2: pt(51.32, 72.43))
        path.addCurve(to: pt(50.31, 70.37), control1: pt(50.63, 71.95), control2: pt(50.31, 71.08))
        path.addLine(to: pt(50.31, 69.03))
        path.addLine(to: pt(50.94, 70.22))
        path.addCurve(to: pt(51.57, 72.03), control1: pt(51.26, 70.85), control2: pt(51.57, 71.72))
        path.closeSubpath()
        path.move(to: pt(79.31, 71.56))
        path.addCurve(to: pt(78.99, 70.61), control1: pt(78.55, 73.14), control2: pt(78.43, 72.66))
        path.addCurve(to: pt(79.69, 69.74), control1: pt(79.25, 69.9), control2: pt(79.56, 69.51))
        path.addCurve(to: pt(79.31, 71.56), control1: pt(79.87, 69.9), control2: pt(79.69, 70.77))
        path.closeSubpath()
        path.move(to: pt(92.08, 76.13))
        path.addCurve(to: pt(90.25, 77.24), control1: pt(91.45, 76.77), control2: pt(90.63, 77.24))
        path.addCurve(to: pt(91.19, 75.74), control1: pt(89.94, 77.32), control2: pt(90.31, 76.61))
        path.addCurve(to: pt(93.02, 74.64), control1: pt(92.08, 74.95), control2: pt(92.89, 74.4))
        path.addCurve(to: pt(92.08, 76.13), control1: pt(93.21, 74.79), control2: pt(92.77, 75.5))
        path.closeSubpath()
        path.move(to: pt(89.31, 78.11))
        path.addCurve(to: pt(88.62, 78.9), control1: pt(89.31, 78.5), control2: pt(88.99, 78.9))
        path.addCurve(to: pt(88.36, 78.11), control1: pt(88.3, 78.9), control2: pt(88.18, 78.5))
        path.addCurve(to: pt(89.06, 77.32), control1: pt(88.55, 77.63), control2: pt(88.87, 77.32))
        path.addCurve(to: pt(89.31, 78.11), control1: pt(89.18, 77.32), control2: pt(89.31, 77.63))
        path.closeSubpath()
        path.move(to: pt(63.52, 89.7))
        path.addCurve(to: pt(61.01, 90.57), control1: pt(62.64, 94.75), control2: pt(61.95, 94.99))
        path.addLine(to: pt(60.25, 87.34))
        path.addLine(to: pt(60.94, 85.44))
        path.addCurve(to: pt(61.64, 81.34), control1: pt(61.32, 84.42), control2: pt(61.64, 82.6))
        path.addCurve(to: pt(63.4, 81.81), control1: pt(61.64, 77.63), control2: pt(62.52, 77.79))
        path.addLine(to: pt(64.21, 85.6))
        path.addLine(to: pt(63.52, 89.7))
        path.closeSubpath()
        path.move(to: pt(87.11, 79.68))
        path.addCurve(to: pt(85.97, 80.47), control1: pt(86.92, 80.08), control2: pt(86.35, 80.47))
        path.addLine(to: pt(85.22, 80.47))
        path.addLine(to: pt(86.16, 79.68))
        path.addCurve(to: pt(87.11, 79.68), control1: pt(87.36, 78.74), control2: pt(87.61, 78.74))
        path.closeSubpath()
        path.move(to: pt(56.29, 86.15))
        path.addCurve(to: pt(61.51, 106.11), control1: pt(57.86, 87.34), control2: pt(61.82, 102.56))
        path.addLine(to: pt(61.32, 108.48))
        path.addLine(to: pt(59.75, 105.4))
        path.addCurve(to: pt(56.54, 99.88), control1: pt(58.93, 103.67), control2: pt(57.48, 101.14))
        path.addLine(to: pt(54.91, 97.44))
        path.addLine(to: pt(54.53, 92.7))
        path.addCurve(to: pt(53.71, 84.81), control1: pt(54.28, 90.1), control2: pt(53.9, 86.55))
        path.addLine(to: pt(53.33, 81.66))
        path.addLine(to: pt(54.47, 83.63))
        path.addCurve(to: pt(56.29, 86.15), control1: pt(55.09, 84.73), control2: pt(55.91, 85.84))
        path.closeSubpath()
        path.move(to: pt(78.87, 87.02))
        path.addCurve(to: pt(75.53, 96.88), control1: pt(78.05, 88.92), control2: pt(76.54, 93.41))
        path.addCurve(to: pt(73.14, 104.38), control1: pt(74.53, 100.43), control2: pt(73.46, 103.83))
        path.addCurve(to: pt(67.04, 113.61), control1: pt(71.95, 106.98), control2: pt(67.55, 113.53))
        path.addLine(to: pt(66.54, 113.61))
        path.addLine(to: pt(66.79, 108.64))
        path.addLine(to: pt(67.04, 103.75))
        path.addLine(to: pt(69.43, 97.44))
        path.addCurve(to: pt(73.08, 88.92), control1: pt(70.75, 93.96), control2: pt(72.39, 90.18))
        path.addCurve(to: pt(79.69, 83.63), control1: pt(74.28, 86.86), control2: pt(78.11, 83.71))
        path.addLine(to: pt(80.44, 83.63))
        path.addLine(to: pt(78.87, 87.02))
        path.closeSubpath()
        path.move(to: pt(83.02, 94.91))
        path.addCurve(to: pt(81.64, 96.73), control1: pt(83.02, 95.07), control2: pt(82.39, 95.86))
        path.addLine(to: pt(80.19, 98.22))
        path.addLine(to: pt(81.38, 96.41))
        path.addCurve(to: pt(83.02, 94.91), control1: pt(82.52, 94.75), control2: pt(83.02, 94.28))
        path.closeSubpath()
        return path
    }

    static func leaf(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(59.82, 8.44))
        path.addCurve(to: pt(13.86, 41.89), control1: pt(37.54, 18.46), control2: pt(24.56, 27.93))
        path.addLine(to: pt(8.25, 49.31))
        path.addLine(to: pt(8.07, 61.93))
        path.addLine(to: pt(7.89, 74.56))
        path.addLine(to: pt(11.93, 80.47))
        path.addCurve(to: pt(63.33, 115.11), control1: pt(19.47, 91.36), control2: pt(39.12, 104.62))
        path.addLine(to: pt(66.14, 116.37))
        path.addLine(to: pt(67.37, 121.1))
        path.addCurve(to: pt(69.47, 128.05), control1: pt(68.07, 123.71), control2: pt(68.95, 126.79))
        path.addLine(to: pt(70.53, 130.18))
        path.addLine(to: pt(73.16, 130.18))
        path.addLine(to: pt(75.96, 130.18))
        path.addLine(to: pt(74.91, 124.1))
        path.addLine(to: pt(73.86, 117.95))
        path.addLine(to: pt(76.49, 115.58))
        path.addCurve(to: pt(88.77, 107.3), control1: pt(77.89, 114.32), control2: pt(83.33, 110.53))
        path.addCurve(to: pt(122.11, 76.92), control1: pt(106.49, 96.65), control2: pt(115.44, 88.44))
        path.addLine(to: pt(125.44, 71.4))
        path.addLine(to: pt(125.26, 60.75))
        path.addLine(to: pt(125.26, 50.1))
        path.addLine(to: pt(121.23, 44.18))
        path.addCurve(to: pt(111.05, 32.35), control1: pt(118.95, 40.95), control2: pt(114.39, 35.58))
        path.addCurve(to: pt(73.33, 3.47), control1: pt(104.56, 25.96), control2: pt(76.14, 4.26))
        path.addCurve(to: pt(59.82, 8.44), control1: pt(72.46, 3.23), control2: pt(66.32, 5.44))
        path.closeSubpath()
        path.move(to: pt(68.07, 96.25))
        path.addLine(to: pt(68.07, 114.0))
        path.addLine(to: pt(66.67, 111.64))
        path.addCurve(to: pt(65.26, 90.34), control1: pt(65.96, 110.3), control2: pt(65.26, 100.75))
        path.addLine(to: pt(65.44, 71.4))
        path.addLine(to: pt(66.84, 74.95))
        path.addCurve(to: pt(68.07, 96.25), control1: pt(67.54, 76.92), control2: pt(68.07, 86.47))
        path.closeSubpath()
        return path
    }

    static func samaraCluster1(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(75.2, 5.65))
        path.addCurve(to: pt(75.52, 9.38), control1: pt(74.77, 6.44), control2: pt(74.88, 8.14))
        path.addCurve(to: pt(78.93, 24.18), control1: pt(77.12, 13.11), control2: pt(78.93, 20.79))
        path.addCurve(to: pt(68.59, 53.33), control1: pt(78.93, 32.66), control2: pt(73.28, 48.59))
        path.addLine(to: pt(66.35, 55.59))
        path.addLine(to: pt(62.61, 54.35))
        path.addLine(to: pt(58.88, 52.99))
        path.addLine(to: pt(55.89, 53.79))
        path.addCurve(to: pt(49.49, 56.61), control1: pt(54.19, 54.24), control2: pt(51.31, 55.48))
        path.addCurve(to: pt(36.16, 62.15), control1: pt(47.68, 57.63), control2: pt(41.6, 60.23))
        path.addCurve(to: pt(4.27, 82.49), control1: pt(16.43, 69.27), control2: pt(4.16, 77.06))
        path.addCurve(to: pt(18.77, 90.4), control1: pt(4.37, 87.12), control2: pt(10.35, 90.4))
        path.addLine(to: pt(24.64, 90.4))
        path.addLine(to: pt(27.84, 88.59))
        path.addCurve(to: pt(38.72, 79.44), control1: pt(29.65, 87.68), control2: pt(34.45, 83.5))
        path.addCurve(to: pt(57.28, 68.93), control1: pt(47.15, 71.19), control2: pt(51.2, 68.93))
        path.addLine(to: pt(61.33, 68.93))
        path.addLine(to: pt(63.79, 72.88))
        path.addCurve(to: pt(66.13, 79.1), control1: pt(65.07, 75.03), control2: pt(66.13, 77.85))
        path.addLine(to: pt(66.13, 81.36))
        path.addLine(to: pt(64.53, 81.36))
        path.addCurve(to: pt(43.84, 103.28), control1: pt(62.29, 81.36), control2: pt(47.68, 96.84))
        path.addLine(to: pt(40.53, 108.93))
        path.addLine(to: pt(40.53, 112.66))
        path.addLine(to: pt(40.53, 116.38))
        path.addLine(to: pt(43.09, 117.63))
        path.addLine(to: pt(45.65, 118.98))
        path.addLine(to: pt(50.35, 118.19))
        path.addCurve(to: pt(58.45, 115.25), control1: pt(52.91, 117.74), control2: pt(56.53, 116.5))
        path.addLine(to: pt(61.87, 112.99))
        path.addLine(to: pt(61.97, 107.68))
        path.addCurve(to: pt(62.93, 100.0), control1: pt(61.97, 104.63), control2: pt(62.4, 101.24))
        path.addLine(to: pt(63.89, 97.74))
        path.addLine(to: pt(63.89, 106.33))
        path.addLine(to: pt(64.0, 114.8))
        path.addLine(to: pt(67.09, 120.0))
        path.addCurve(to: pt(82.24, 126.89), control1: pt(72.11, 128.36), control2: pt(78.72, 131.41))
        path.addLine(to: pt(83.73, 125.08))
        path.addLine(to: pt(83.63, 112.54))
        path.addLine(to: pt(83.52, 100.0))
        path.addLine(to: pt(81.17, 91.19))
        path.addCurve(to: pt(81.6, 81.02), control1: pt(78.83, 82.03), control2: pt(78.93, 79.89))
        path.addCurve(to: pt(84.8, 80.23), control1: pt(82.56, 81.36), control2: pt(83.95, 81.02))
        path.addLine(to: pt(86.29, 78.87))
        path.addLine(to: pt(90.99, 82.26))
        path.addCurve(to: pt(100.59, 99.55), control1: pt(97.49, 87.12), control2: pt(97.81, 87.68))
        path.addCurve(to: pt(117.01, 124.86), control1: pt(104.32, 115.48), control2: pt(107.84, 120.79))
        path.addCurve(to: pt(129.07, 119.77), control1: pt(124.91, 128.36), control2: pt(129.07, 126.55))
        path.addLine(to: pt(129.07, 115.59))
        path.addLine(to: pt(125.87, 108.93))
        path.addCurve(to: pt(113.07, 89.38), control1: pt(124.16, 105.31), control2: pt(118.4, 96.5))
        path.addCurve(to: pt(101.76, 73.33), control1: pt(107.73, 82.26), control2: pt(102.61, 75.03))
        path.addCurve(to: pt(92.27, 65.42), control1: pt(100.16, 69.83), control2: pt(95.47, 65.99))
        path.addLine(to: pt(90.13, 64.97))
        path.addLine(to: pt(89.39, 57.63))
        path.addCurve(to: pt(85.55, 33.9), control1: pt(88.43, 48.36), control2: pt(86.83, 38.98))
        path.addCurve(to: pt(81.71, 18.64), control1: pt(84.91, 31.75), control2: pt(83.2, 24.86))
        path.addCurve(to: pt(77.44, 5.88), control1: pt(80.11, 12.43), control2: pt(78.19, 6.67))
        path.addLine(to: pt(75.95, 4.29))
        path.addLine(to: pt(75.2, 5.65))
        path.closeSubpath()
        path.move(to: pt(84.05, 39.21))
        path.addCurve(to: pt(81.49, 65.54), control1: pt(88.0, 59.66), control2: pt(87.47, 65.54))
        path.addLine(to: pt(78.93, 65.54))
        path.addLine(to: pt(78.93, 66.89))
        path.addLine(to: pt(78.83, 68.36))
        path.addLine(to: pt(77.33, 66.1))
        path.addCurve(to: pt(72.96, 60.79), control1: pt(76.48, 64.86), control2: pt(74.56, 62.49))
        path.addLine(to: pt(70.29, 57.85))
        path.addLine(to: pt(74.56, 49.15))
        path.addCurve(to: pt(78.93, 39.55), control1: pt(77.01, 44.41), control2: pt(78.93, 40.0))
        path.addCurve(to: pt(81.92, 32.77), control1: pt(78.93, 37.63), control2: pt(81.07, 32.77))
        path.addCurve(to: pt(84.05, 39.21), control1: pt(82.35, 32.77), control2: pt(83.31, 35.71))
        path.closeSubpath()
        path.move(to: pt(65.39, 92.09))
        path.addCurve(to: pt(64.32, 93.33), control1: pt(65.07, 93.11), control2: pt(64.53, 93.67))
        path.addCurve(to: pt(64.53, 91.64), control1: pt(64.0, 92.99), control2: pt(64.11, 92.32))
        path.addCurve(to: pt(65.39, 92.09), control1: pt(65.49, 89.83), control2: pt(66.13, 90.17))
        path.closeSubpath()
        return path
    }

    static func samaraCluster2(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(67.92, 8.12))
        path.addCurve(to: pt(59.37, 34.55), control1: pt(64.48, 19.15), control2: pt(60.1, 32.48))
        path.addCurve(to: pt(56.25, 50.42), control1: pt(57.81, 39.15), control2: pt(56.25, 46.91))
        path.addCurve(to: pt(54.69, 56.48), control1: pt(56.25, 52.36), control2: pt(55.52, 55.15))
        path.addLine(to: pt(53.23, 59.03))
        path.addLine(to: pt(48.96, 59.76))
        path.addLine(to: pt(44.79, 60.36))
        path.addLine(to: pt(38.02, 67.76))
        path.addCurve(to: pt(25.31, 79.76), control1: pt(34.27, 71.76), control2: pt(28.54, 77.21))
        path.addCurve(to: pt(5.94, 101.94), control1: pt(16.98, 86.3), control2: pt(7.71, 96.97))
        path.addLine(to: pt(4.48, 106.06))
        path.addLine(to: pt(5.52, 108.73))
        path.addLine(to: pt(6.56, 111.52))
        path.addLine(to: pt(10.0, 112.24))
        path.addCurve(to: pt(30.42, 103.39), control1: pt(16.35, 113.58), control2: pt(25.21, 109.82))
        path.addCurve(to: pt(36.46, 92.0), control1: pt(31.87, 101.58), control2: pt(34.69, 96.36))
        path.addCurve(to: pt(50.1, 76.0), control1: pt(40.31, 82.42), control2: pt(43.65, 78.55))
        path.addLine(to: pt(54.9, 74.18))
        path.addLine(to: pt(58.23, 76.61))
        path.addCurve(to: pt(59.06, 79.15), control1: pt(62.08, 79.52), control2: pt(62.19, 79.88))
        path.addLine(to: pt(56.67, 78.67))
        path.addLine(to: pt(51.87, 87.52))
        path.addCurve(to: pt(39.48, 116.73), control1: pt(45.21, 100.0), control2: pt(40.94, 109.94))
        path.addLine(to: pt(38.23, 122.55))
        path.addLine(to: pt(39.37, 125.58))
        path.addLine(to: pt(40.62, 128.48))
        path.addLine(to: pt(44.37, 128.48))
        path.addLine(to: pt(48.23, 128.48))
        path.addLine(to: pt(52.71, 125.45))
        path.addLine(to: pt(57.19, 122.3))
        path.addLine(to: pt(59.79, 117.21))
        path.addCurve(to: pt(64.9, 90.06), control1: pt(62.4, 111.88), control2: pt(64.37, 100.97))
        path.addCurve(to: pt(65.31, 83.64), control1: pt(65.0, 86.55), control2: pt(65.21, 83.64))
        path.addCurve(to: pt(69.69, 96.97), control1: pt(66.04, 83.64), control2: pt(68.54, 91.15))
        path.addCurve(to: pt(91.56, 121.21), control1: pt(73.02, 112.73), control2: pt(80.62, 121.21))
        path.addCurve(to: pt(80.62, 83.64), control1: pt(103.33, 121.21), control2: pt(99.17, 106.79))
        path.addCurve(to: pt(69.58, 65.45), control1: pt(74.69, 76.24), control2: pt(68.12, 65.45))
        path.addCurve(to: pt(71.87, 68.48), control1: pt(70.1, 65.45), control2: pt(71.15, 66.79))
        path.addCurve(to: pt(82.29, 75.15), control1: pt(73.33, 71.76), control2: pt(78.75, 75.15))
        path.addCurve(to: pt(94.79, 87.39), control1: pt(85.83, 75.15), control2: pt(90.21, 79.52))
        path.addCurve(to: pt(107.6, 102.67), control1: pt(99.9, 96.0), control2: pt(103.12, 99.88))
        path.addLine(to: pt(110.94, 104.73))
        path.addLine(to: pt(117.81, 104.73))
        path.addLine(to: pt(124.79, 104.85))
        path.addLine(to: pt(126.98, 102.55))
        path.addCurve(to: pt(129.17, 98.18), control1: pt(128.23, 101.21), control2: pt(129.17, 99.27))
        path.addCurve(to: pt(100.52, 70.91), control1: pt(129.17, 92.85), control2: pt(117.5, 81.7))
        path.addCurve(to: pt(88.75, 62.55), control1: pt(96.56, 68.36), control2: pt(91.15, 64.61))
        path.addLine(to: pt(84.17, 58.79))
        path.addLine(to: pt(78.96, 58.18))
        path.addLine(to: pt(73.85, 57.58))
        path.addLine(to: pt(72.4, 54.55))
        path.addCurve(to: pt(69.9, 12.73), control1: pt(66.04, 40.24), control2: pt(65.1, 25.7))
        path.addCurve(to: pt(70.21, 5.21), control1: pt(71.25, 8.85), control2: pt(71.46, 5.7))
        path.addCurve(to: pt(67.92, 8.12), control1: pt(69.58, 4.97), control2: pt(68.54, 6.3))
        path.closeSubpath()
        path.move(to: pt(65.52, 39.64))
        path.addCurve(to: pt(68.33, 51.76), control1: pt(66.25, 43.52), control2: pt(67.5, 48.97))
        path.addLine(to: pt(69.79, 56.97))
        path.addLine(to: pt(69.17, 60.61))
        path.addCurve(to: pt(66.15, 63.03), control1: pt(68.44, 64.24), control2: pt(67.29, 65.21))
        path.addCurve(to: pt(61.87, 60.0), control1: pt(65.73, 62.3), control2: pt(63.85, 60.97))
        path.addLine(to: pt(58.33, 58.3))
        path.addLine(to: pt(58.33, 54.06))
        path.addCurve(to: pt(63.44, 32.73), control1: pt(58.33, 47.76), control2: pt(61.87, 32.73))
        path.addCurve(to: pt(65.52, 39.64), control1: pt(63.75, 32.73), control2: pt(64.69, 35.88))
        path.closeSubpath()
        return path
    }

    static func samaraCluster3(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(73.39, 16.73))
        path.addLine(to: pt(73.81, 28.77))
        path.addLine(to: pt(70.4, 36.49))
        path.addCurve(to: pt(65.39, 45.73), control1: pt(68.59, 40.82), control2: pt(66.35, 44.91))
        path.addLine(to: pt(63.79, 47.25))
        path.addLine(to: pt(59.2, 45.85))
        path.addLine(to: pt(54.61, 44.56))
        path.addLine(to: pt(48.32, 46.67))
        path.addCurve(to: pt(30.93, 51.46), control1: pt(44.91, 47.95), control2: pt(37.12, 50.06))
        path.addCurve(to: pt(4.27, 65.38), control1: pt(13.44, 55.32), control2: pt(4.27, 60.12))
        path.addCurve(to: pt(13.55, 73.68), control1: pt(4.27, 68.3), control2: pt(8.32, 71.81))
        path.addLine(to: pt(18.03, 75.2))
        path.addLine(to: pt(21.97, 74.5))
        path.addCurve(to: pt(31.79, 69.36), control1: pt(24.11, 74.04), control2: pt(28.59, 71.81))
        path.addCurve(to: pt(42.77, 61.64), control1: pt(34.99, 66.9), control2: pt(39.89, 63.39))
        path.addLine(to: pt(48.0, 58.36))
        path.addLine(to: pt(52.91, 59.18))
        path.addLine(to: pt(57.81, 60.0))
        path.addLine(to: pt(58.35, 61.87))
        path.addCurve(to: pt(60.48, 65.61), control1: pt(58.67, 62.92), control2: pt(59.63, 64.56))
        path.addLine(to: pt(61.97, 67.6))
        path.addLine(to: pt(57.39, 72.28))
        path.addCurve(to: pt(45.33, 83.04), control1: pt(54.83, 74.85), control2: pt(49.49, 79.77))
        path.addCurve(to: pt(26.45, 112.63), control1: pt(27.84, 97.19), control2: pt(21.33, 107.6))
        path.addLine(to: pt(28.48, 114.62))
        path.addLine(to: pt(32.32, 114.62))
        path.addCurve(to: pt(40.53, 112.75), control1: pt(34.45, 114.62), control2: pt(38.19, 113.8))
        path.addLine(to: pt(44.8, 110.88))
        path.addLine(to: pt(49.6, 104.91))
        path.addCurve(to: pt(54.4, 100.35), control1: pt(52.27, 101.64), control2: pt(54.4, 99.53))
        path.addCurve(to: pt(55.89, 101.75), control1: pt(54.4, 101.17), control2: pt(55.04, 101.75))
        path.addCurve(to: pt(60.37, 106.9), control1: pt(56.75, 101.75), control2: pt(58.77, 104.09))
        path.addCurve(to: pt(70.29, 115.79), control1: pt(63.15, 111.7), control2: pt(67.73, 115.79))
        path.addCurve(to: pt(73.6, 112.05), control1: pt(70.93, 115.79), control2: pt(72.43, 114.04))
        path.addLine(to: pt(75.73, 108.19))
        path.addLine(to: pt(75.73, 99.18))
        path.addCurve(to: pt(74.67, 87.25), control1: pt(75.73, 94.27), control2: pt(75.31, 88.89))
        path.addCurve(to: pt(77.55, 86.9), control1: pt(73.39, 83.51), control2: pt(74.67, 83.39))
        path.addLine(to: pt(79.68, 89.47))
        path.addLine(to: pt(81.39, 101.4))
        path.addCurve(to: pt(84.91, 117.66), control1: pt(82.24, 107.95), control2: pt(83.84, 115.2))
        path.addLine(to: pt(86.83, 121.99))
        path.addLine(to: pt(91.63, 125.26))
        path.addLine(to: pt(96.43, 128.65))
        path.addLine(to: pt(99.84, 128.65))
        path.addLine(to: pt(103.25, 128.65))
        path.addLine(to: pt(104.53, 126.9))
        path.addLine(to: pt(105.92, 125.15))
        path.addLine(to: pt(105.28, 120.23))
        path.addCurve(to: pt(93.33, 92.4), control1: pt(104.64, 114.85), control2: pt(99.09, 102.11))
        path.addCurve(to: pt(83.2, 70.64), control1: pt(90.03, 87.02), control2: pt(83.2, 72.28))
        path.addCurve(to: pt(90.24, 71.93), control1: pt(83.2, 69.59), control2: pt(87.36, 70.29))
        path.addCurve(to: pt(100.69, 87.49), control1: pt(95.36, 74.74), control2: pt(98.03, 78.6))
        path.addCurve(to: pt(105.71, 100.0), control1: pt(102.08, 92.05), control2: pt(104.32, 97.78))
        path.addLine(to: pt(108.27, 104.09))
        path.addLine(to: pt(113.81, 107.02))
        path.addCurve(to: pt(127.79, 108.54), control1: pt(119.79, 110.18), control2: pt(125.76, 110.76))
        path.addCurve(to: pt(113.71, 79.65), control1: pt(131.73, 104.21), control2: pt(127.36, 95.2))
        path.addCurve(to: pt(99.31, 62.34), control1: pt(107.73, 72.87), control2: pt(101.23, 65.03))
        path.addLine(to: pt(95.89, 57.31))
        path.addLine(to: pt(91.63, 56.14))
        path.addCurve(to: pt(87.04, 53.45), control1: pt(89.28, 55.44), control2: pt(87.15, 54.27))
        path.addCurve(to: pt(85.33, 46.78), control1: pt(86.83, 52.63), control2: pt(86.08, 49.71))
        path.addCurve(to: pt(81.07, 30.41), control1: pt(84.69, 43.86), control2: pt(82.67, 36.49))
        path.addCurve(to: pt(76.69, 11.93), control1: pt(79.36, 24.33), control2: pt(77.33, 16.02))
        path.addLine(to: pt(75.41, 4.68))
        path.addLine(to: pt(74.13, 4.68))
        path.addLine(to: pt(72.85, 4.68))
        path.addLine(to: pt(73.39, 16.73))
        path.closeSubpath()
        path.move(to: pt(75.73, 41.99))
        path.addCurve(to: pt(71.89, 64.21), control1: pt(75.73, 51.35), control2: pt(73.92, 61.75))
        path.addLine(to: pt(70.4, 65.96))
        path.addLine(to: pt(69.65, 65.03))
        path.addCurve(to: pt(70.19, 63.51), control1: pt(69.12, 64.44), control2: pt(69.44, 63.74))
        path.addCurve(to: pt(69.12, 53.45), control1: pt(72.21, 62.69), control2: pt(71.68, 57.43))
        path.addCurve(to: pt(70.51, 41.4), control1: pt(66.24, 49.01), control2: pt(66.35, 47.95))
        path.addCurve(to: pt(73.6, 35.2), control1: pt(72.21, 38.6), control2: pt(73.6, 35.91))
        path.addCurve(to: pt(74.67, 33.92), control1: pt(73.6, 34.5), control2: pt(74.13, 33.92))
        path.addLine(to: pt(75.73, 33.92))
        path.addLine(to: pt(75.73, 41.99))
        path.closeSubpath()
        path.move(to: pt(82.13, 39.88))
        path.addCurve(to: pt(83.41, 47.25), control1: pt(82.13, 41.05), control2: pt(82.67, 44.44))
        path.addLine(to: pt(84.69, 52.4))
        path.addLine(to: pt(83.31, 54.27))
        path.addCurve(to: pt(79.57, 56.14), control1: pt(82.45, 55.32), control2: pt(80.85, 56.14))
        path.addLine(to: pt(77.23, 56.14))
        path.addLine(to: pt(77.55, 48.77))
        path.addCurve(to: pt(78.51, 38.95), control1: pt(77.76, 44.8), control2: pt(78.19, 40.35))
        path.addLine(to: pt(78.93, 36.37))
        path.addLine(to: pt(80.53, 36.96))
        path.addCurve(to: pt(82.13, 39.88), control1: pt(81.39, 37.43), control2: pt(82.13, 38.71))
        path.closeSubpath()
        path.move(to: pt(62.93, 84.68))
        path.addCurve(to: pt(61.87, 85.96), control1: pt(62.93, 85.03), control2: pt(62.51, 85.61))
        path.addCurve(to: pt(60.8, 85.5), control1: pt(61.33, 86.32), control2: pt(60.8, 86.08))
        path.addCurve(to: pt(61.87, 84.21), control1: pt(60.8, 84.8), control2: pt(61.33, 84.21))
        path.addCurve(to: pt(62.93, 84.68), control1: pt(62.51, 84.21), control2: pt(62.93, 84.44))
        path.closeSubpath()
        return path
    }

    static func samaraClusterWide(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(56.16, 5.71))
        path.addCurve(to: pt(56.51, 13.1), control1: pt(55.89, 6.43), control2: pt(56.07, 9.64))
        path.addCurve(to: pt(55.63, 42.14), control1: pt(57.84, 22.74), control2: pt(57.57, 32.5))
        path.addCurve(to: pt(47.15, 57.14), control1: pt(52.63, 57.26), control2: pt(51.48, 59.29))
        path.addCurve(to: pt(37.53, 59.64), control1: pt(44.59, 55.83), control2: pt(41.41, 56.67))
        path.addCurve(to: pt(27.37, 64.64), control1: pt(36.11, 60.83), control2: pt(31.52, 63.1))
        path.addCurve(to: pt(6.0, 77.02), control1: pt(16.69, 68.81), control2: pt(8.83, 73.33))
        path.addLine(to: pt(3.53, 80.24))
        path.addLine(to: pt(3.53, 82.98))
        path.addLine(to: pt(3.53, 85.71))
        path.addLine(to: pt(6.36, 88.1))
        path.addLine(to: pt(9.27, 90.48))
        path.addLine(to: pt(14.39, 90.48))
        path.addCurve(to: pt(29.14, 80.95), control1: pt(20.57, 90.48), control2: pt(21.81, 89.76))
        path.addCurve(to: pt(43.09, 71.43), control1: pt(36.47, 72.38), control2: pt(37.79, 71.43))
        path.addLine(to: pt(47.42, 71.43))
        path.addLine(to: pt(49.8, 76.07))
        path.addLine(to: pt(52.19, 80.6))
        path.addLine(to: pt(51.92, 96.55))
        path.addLine(to: pt(51.74, 112.5))
        path.addLine(to: pt(52.98, 115.48))
        path.addCurve(to: pt(62.43, 126.9), control1: pt(54.92, 119.88), control2: pt(60.04, 126.19))
        path.addLine(to: pt(64.55, 127.62))
        path.addLine(to: pt(66.23, 125.6))
        path.addLine(to: pt(67.99, 123.45))
        path.addLine(to: pt(67.99, 117.38))
        path.addCurve(to: pt(61.37, 81.07), control1: pt(67.99, 111.67), control2: pt(66.75, 104.76))
        path.addCurve(to: pt(59.16, 69.05), control1: pt(60.13, 75.6), control2: pt(59.16, 70.24))
        path.addCurve(to: pt(56.51, 63.93), control1: pt(59.16, 67.86), control2: pt(58.01, 65.48))
        path.addCurve(to: pt(53.86, 59.29), control1: pt(55.1, 62.26), control2: pt(53.86, 60.12))
        path.addCurve(to: pt(56.6, 48.21), control1: pt(53.86, 57.62), control2: pt(55.72, 50.24))
        path.addCurve(to: pt(58.28, 41.31), control1: pt(56.87, 47.5), control2: pt(57.66, 44.52))
        path.addCurve(to: pt(60.93, 37.26), control1: pt(59.34, 36.19), control2: pt(60.93, 33.69))
        path.addCurve(to: pt(64.46, 44.05), control1: pt(60.93, 38.1), control2: pt(62.52, 41.19))
        path.addCurve(to: pt(69.49, 52.14), control1: pt(66.49, 47.02), control2: pt(68.7, 50.6))
        path.addLine(to: pt(70.91, 54.88))
        path.addLine(to: pt(69.32, 59.52))
        path.addLine(to: pt(67.81, 64.17))
        path.addLine(to: pt(68.26, 67.5))
        path.addCurve(to: pt(70.02, 79.76), control1: pt(68.52, 69.29), control2: pt(69.32, 74.88))
        path.addCurve(to: pt(72.41, 100.0), control1: pt(70.73, 84.64), control2: pt(71.88, 93.81))
        path.addCurve(to: pt(82.65, 128.57), control1: pt(74.08, 117.86), control2: pt(77.97, 128.57))
        path.addLine(to: pt(84.68, 128.57))
        path.addLine(to: pt(86.89, 124.64))
        path.addCurve(to: pt(89.98, 115.83), control1: pt(88.04, 122.62), control2: pt(89.45, 118.57))
        path.addLine(to: pt(90.95, 110.83))
        path.addLine(to: pt(90.07, 105.36))
        path.addCurve(to: pt(85.47, 91.9), control1: pt(89.54, 102.38), control2: pt(87.51, 96.31))
        path.addCurve(to: pt(80.09, 66.19), control1: pt(78.94, 77.5), control2: pt(78.76, 76.79))
        path.addLine(to: pt(80.62, 61.67))
        path.addLine(to: pt(85.39, 58.69))
        path.addLine(to: pt(90.15, 55.71))
        path.addLine(to: pt(94.3, 56.55))
        path.addCurve(to: pt(104.64, 59.52), control1: pt(96.51, 57.02), control2: pt(101.19, 58.33))
        path.addLine(to: pt(110.91, 61.67))
        path.addLine(to: pt(115.14, 60.6))
        path.addCurve(to: pt(127.77, 50.36), control1: pt(120.44, 59.29), control2: pt(124.68, 55.83))
        path.addLine(to: pt(130.15, 46.19))
        path.addLine(to: pt(129.27, 44.29))
        path.addCurve(to: pt(125.3, 40.12), control1: pt(128.74, 43.1), control2: pt(126.98, 41.31))
        path.addLine(to: pt(122.3, 37.98))
        path.addLine(to: pt(116.11, 38.57))
        path.addCurve(to: pt(101.99, 41.19), control1: pt(112.76, 38.93), control2: pt(106.4, 40.12))
        path.addCurve(to: pt(86.71, 43.93), control1: pt(97.66, 42.14), control2: pt(90.77, 43.45))
        path.addLine(to: pt(79.38, 44.88))
        path.addLine(to: pt(76.82, 47.5))
        path.addCurve(to: pt(72.32, 50.0), control1: pt(75.41, 48.81), control2: pt(73.38, 50.0))
        path.addLine(to: pt(70.46, 50.0))
        path.addLine(to: pt(67.46, 45.48))
        path.addCurve(to: pt(60.49, 29.17), control1: pt(64.81, 41.43), control2: pt(61.99, 35.0))
        path.addCurve(to: pt(59.25, 16.19), control1: pt(60.13, 27.86), control2: pt(59.6, 22.02))
        path.addLine(to: pt(58.72, 5.6))
        path.addLine(to: pt(57.66, 5.12))
        path.addCurve(to: pt(56.16, 5.71), control1: pt(57.13, 4.88), control2: pt(56.42, 5.12))
        path.closeSubpath()
        return path
    }

    static func samara(_ rect: CGRect) -> Path {
        var path = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { LeafIDGlyphPaths.pt(rect, x, y) }
        path.move(to: pt(36.35, 8.5))
        path.addLine(to: pt(34.39, 12.39))
        path.addLine(to: pt(34.53, 25.37))
        path.addLine(to: pt(34.67, 38.35))
        path.addLine(to: pt(37.89, 46.49))
        path.addLine(to: pt(40.98, 54.51))
        path.addLine(to: pt(35.37, 58.88))
        path.addLine(to: pt(29.61, 63.13))
        path.addLine(to: pt(26.53, 70.8))
        path.addCurve(to: pt(18.25, 88.02), control1: pt(24.84, 75.04), control2: pt(21.19, 82.71))
        path.addCurve(to: pt(9.82, 105.01), control1: pt(15.3, 93.22), control2: pt(11.51, 100.88))
        path.addLine(to: pt(6.6, 112.57))
        path.addLine(to: pt(6.46, 118.7))
        path.addLine(to: pt(6.46, 124.84))
        path.addLine(to: pt(8.28, 126.73))
        path.addCurve(to: pt(35.93, 112.21), control1: pt(13.61, 132.15), control2: pt(30.46, 123.3))
        path.addLine(to: pt(37.89, 108.32))
        path.addLine(to: pt(37.89, 95.34))
        path.addLine(to: pt(37.89, 82.48))
        path.addLine(to: pt(39.44, 79.88))
        path.addCurve(to: pt(45.33, 73.51), control1: pt(40.28, 78.47), control2: pt(42.95, 75.52))
        path.addLine(to: pt(49.68, 69.62))
        path.addLine(to: pt(55.3, 69.62))
        path.addCurve(to: pt(66.81, 72.09), control1: pt(58.39, 69.62), control2: pt(63.58, 70.68))
        path.addLine(to: pt(72.7, 74.45))
        path.addLine(to: pt(78.18, 80.0))
        path.addCurve(to: pt(94.04, 93.33), control1: pt(85.47, 87.67), control2: pt(88.28, 90.03))
        path.addLine(to: pt(98.95, 96.17))
        path.addLine(to: pt(109.61, 96.17))
        path.addLine(to: pt(120.28, 96.17))
        path.addLine(to: pt(123.93, 94.51))
        path.addLine(to: pt(127.72, 92.86))
        path.addLine(to: pt(127.72, 89.68))
        path.addLine(to: pt(127.72, 86.61))
        path.addLine(to: pt(121.82, 81.77))
        path.addLine(to: pt(115.79, 76.81))
        path.addLine(to: pt(104.28, 72.09))
        path.addCurve(to: pt(92.07, 67.26), control1: pt(97.96, 69.38), control2: pt(92.49, 67.26))
        path.addCurve(to: pt(67.65, 56.87), control1: pt(89.82, 67.26), control2: pt(71.86, 59.59))
        path.addLine(to: pt(62.74, 53.69))
        path.addLine(to: pt(53.61, 53.1))
        path.addLine(to: pt(44.49, 52.51))
        path.addLine(to: pt(41.12, 44.84))
        path.addLine(to: pt(37.75, 37.17))
        path.addLine(to: pt(38.46, 25.37))
        path.addCurve(to: pt(40.0, 9.09), control1: pt(38.74, 18.88), control2: pt(39.44, 11.56))
        path.addLine(to: pt(40.98, 4.72))
        path.addLine(to: pt(39.58, 4.72))
        path.addCurve(to: pt(36.35, 8.5), control1: pt(38.88, 4.72), control2: pt(37.33, 6.49))
        path.closeSubpath()
        return path
    }

}

private struct LeafIDGlyphShape: Shape {
    let builder: (CGRect) -> Path
    func path(in rect: CGRect) -> Path { builder(rect) }
}

/// Drop-in replacement for `Image(systemName:)` using LeafID's own botanical glyph family instead of
/// generic SF Symbols. Every kind shares the same outline/filled/circle style contract and size/weight/
/// color API as `Image(systemName:).font(.system(size:weight:))` for a near 1:1 swap at call sites.
struct LeafIDIcon: View {
    enum Kind {
        case samara, leaf, mapleLeaf, oakLeaf, acorn, pinecone, berry, flower, tree, sprout
        /// Vector-traced from reference art (potrace) rather than hand-authored — natural aspect ratio, not square.
        case leafSpray1, leafSpray2, leafSpray3
        case samaraCluster1, samaraCluster2, samaraCluster3, samaraClusterWide

        /// Width ÷ height of the glyph's own design grid. 1 for the hand-authored square glyphs;
        /// the traced glyphs keep the proportions of the artwork they were traced from.
        var aspectRatio: CGFloat {
            switch self {
            case .leafSpray1: return 200.0 / 168.0
            case .leafSpray2: return 154.0 / 178.0
            case .leafSpray3: return 212.0 / 169.0
            case .samaraCluster1: return 125.0 / 118.0
            case .samaraCluster2: return 128.0 / 110.0
            case .samaraCluster3: return 125.0 / 114.0
            case .samaraClusterWide: return 151.0 / 112.0
            case .samara: return 95.0 / 113.0
            case .leaf: return 76.0 / 169.0
            case .mapleLeaf, .oakLeaf, .acorn, .pinecone, .berry, .flower, .tree, .sprout: return 1
            }
        }
    }

    enum Style {
        case outline
        case filled
        case circleOutline
        case circleFilled
    }

    var kind: Kind
    var style: Style = .filled
    var size: CGFloat = 24
    /// Line weight for outline strokes; defaults to a size-relative weight matching SF's regular cut.
    var weight: CGFloat? = nil
    var showsVein: Bool = false
    var color: Color = .primary

    private var strokeWidth: CGFloat {
        weight ?? max(1.4, size * 0.09)
    }

    private var mainBuilder: (CGRect) -> Path {
        switch kind {
        case .samara: return LeafIDGlyphPaths.samara
        case .leaf: return LeafIDGlyphPaths.leaf
        case .mapleLeaf: return LeafIDGlyphPaths.mapleLeaf
        case .oakLeaf: return LeafIDGlyphPaths.oakLeaf
        case .acorn: return LeafIDGlyphPaths.acorn
        case .pinecone: return LeafIDGlyphPaths.pinecone
        case .berry: return LeafIDGlyphPaths.berry
        case .flower: return LeafIDGlyphPaths.flower
        case .tree: return LeafIDGlyphPaths.tree
        case .sprout: return LeafIDGlyphPaths.sprout
        case .leafSpray1: return LeafIDGlyphPaths.leafSpray1
        case .leafSpray2: return LeafIDGlyphPaths.leafSpray2
        case .leafSpray3: return LeafIDGlyphPaths.leafSpray3
        case .samaraCluster1: return LeafIDGlyphPaths.samaraCluster1
        case .samaraCluster2: return LeafIDGlyphPaths.samaraCluster2
        case .samaraCluster3: return LeafIDGlyphPaths.samaraCluster3
        case .samaraClusterWide: return LeafIDGlyphPaths.samaraClusterWide
        }
    }

    /// Traced glyphs bake their vein/stem detail into the main silhouette as negative space, so they have no separate vein overlay.
    private var veinBuilder: ((CGRect) -> Path)? {
        switch kind {
        case .mapleLeaf: return LeafIDGlyphPaths.mapleVein
        case .oakLeaf: return LeafIDGlyphPaths.oakVein
        case .acorn: return LeafIDGlyphPaths.acornVein
        case .pinecone: return LeafIDGlyphPaths.pineconeVein
        case .samara, .leaf, .berry, .flower, .tree, .sprout,
             .leafSpray1, .leafSpray2, .leafSpray3,
             .samaraCluster1, .samaraCluster2, .samaraCluster3, .samaraClusterWide:
            return nil
        }
    }

    var body: some View {
        Group {
            switch style {
            case .outline:
                markOutline
                    .frame(width: size * kind.aspectRatio, height: size)
            case .filled:
                markFilled
                    .frame(width: size * kind.aspectRatio, height: size)
            case .circleOutline:
                ZStack {
                    Circle().strokeBorder(color, lineWidth: strokeWidth)
                    markFilled
                        .aspectRatio(kind.aspectRatio, contentMode: .fit)
                        .padding(size * 0.22)
                }
                .frame(width: size, height: size)
            case .circleFilled:
                ZStack {
                    Circle().fill(color.opacity(0.32))
                    markFilled
                        .aspectRatio(kind.aspectRatio, contentMode: .fit)
                        .padding(size * 0.2)
                }
                .frame(width: size, height: size)
            }
        }
        .compositingGroup()
    }

    private var markOutline: some View {
        LeafIDGlyphShape(builder: mainBuilder)
            .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
    }

    private var markFilled: some View {
        ZStack {
            LeafIDGlyphShape(builder: mainBuilder).fill(color)
            if showsVein, let veinBuilder {
                LeafIDGlyphShape(builder: veinBuilder)
                    .stroke(Color.white.opacity(0.32), style: StrokeStyle(lineWidth: max(1, strokeWidth * 0.4), lineCap: .round))
            }
        }
    }
}

struct LeafIDIcon_Previews: PreviewProvider {
    static let kinds: [LeafIDIcon.Kind] = LeafIDIcon.Kind.allCases

    static var previews: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                ForEach(kinds, id: \.self) { kind in
                    LeafIDIcon(kind: kind, style: .filled, size: 36, showsVein: true, color: LeafIDTheme.primary)
                }
            }
            HStack(spacing: 16) {
                ForEach(kinds, id: \.self) { kind in
                    LeafIDIcon(kind: kind, style: .outline, size: 36, color: LeafIDTheme.onSurfaceVariant)
                }
            }
        }
        .padding(32)
        .background(LeafIDTheme.surface)
        .preferredColorScheme(.dark)
    }
}

extension LeafIDIcon.Kind: CaseIterable, Hashable {}
