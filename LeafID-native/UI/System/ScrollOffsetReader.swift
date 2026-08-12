//
//  ScrollOffsetReader.swift
//  LeafID-native
//
//  Reads live scroll offset via UIScrollView KVO instead of the SwiftUI
//  PreferenceKey/GeometryReader-sentinel pattern, which proved unreliable
//  here — it fired once at initial layout and never updated on real scroll
//  (confirmed via live device log during Druid header collapse debugging).
//

import SwiftUI
#if canImport(UIKit)
import UIKit

struct ScrollOffsetReader: UIViewRepresentable {
    @Binding var offsetY: CGFloat

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                context.coordinator.observe(scrollView)
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(offsetY: $offsetY)
    }

    final class Coordinator: NSObject {
        @Binding var offsetY: CGFloat
        private var observation: NSKeyValueObservation?

        init(offsetY: Binding<CGFloat>) {
            _offsetY = offsetY
        }

        func observe(_ scrollView: UIScrollView) {
            offsetY = scrollView.contentOffset.y
            observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, change in
                guard let newValue = change.newValue?.y else { return }
                DispatchQueue.main.async {
                    self?.offsetY = newValue
                }
            }
        }
    }
}

private extension UIView {
    var enclosingScrollView: UIScrollView? {
        var current: UIView? = superview
        while let view = current {
            if let scrollView = view as? UIScrollView { return scrollView }
            current = view.superview
        }
        return nil
    }
}
#endif
