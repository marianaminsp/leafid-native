//
//  MatchConfidenceBadge.swift
//  LeafID-native
//
//  Bento chip vs results-header pill (`ScanResults.png` — glass capsule, light text).
//

import SwiftUI

struct MatchConfidenceBadge: View {
    let confidence: Double
    /// Full-width results header: glass pill + `onSurface` text (not dark onPrimary chip).
    var useResultsTitle: Bool = false

    private var title: String {
        let n = Int((confidence * 100).rounded())
        if useResultsTitle {
            return "\(n)% Match Confidence"
        }
        return "\(n)% match"
    }

    var body: some View {
        Text(title)
            .font(LeafIDFont.manrope(size: useResultsTitle ? 12 : 12, weight: .bold))
            .tracking(useResultsTitle ? 0.2 : 0.4)
            .foregroundStyle(useResultsTitle ? LeafIDTheme.onSurface : LeafIDTheme.onPrimaryContainer)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, useResultsTitle ? LeafIDTheme.space16 : LeafIDTheme.space12)
            .padding(.vertical, LeafIDTheme.space10)
            .background {
                if useResultsTitle {
                    Capsule()
                        .fill(.ultraThinMaterial)
                } else {
                    Capsule()
                        .fill(LeafIDTheme.primary.opacity(0.22))
                }
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        useResultsTitle ? LeafIDTheme.chromeHighlight.opacity(0.22) : LeafIDTheme.primary.opacity(0.45),
                        lineWidth: 1
                    )
            }
    }
}
