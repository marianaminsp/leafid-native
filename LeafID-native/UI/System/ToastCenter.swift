//
//  ToastCenter.swift
//  LeafID-native
//
//  Lightweight global toasts (§4.1 / §3.11). Host with `.leafIDToastHost()` on a root container.
//

import SwiftUI

enum LeafIDToastKind: Equatable {
    case success
    case error
}

struct LeafIDToastItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let kind: LeafIDToastKind
}

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published private(set) var current: LeafIDToastItem?

    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ message: String, kind: LeafIDToastKind = .success, duration: TimeInterval = 3.6) {
        dismissTask?.cancel()
        let item = LeafIDToastItem(message: message, kind: kind)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            current = item
        }
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self?.current?.id == item.id else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    self?.current = nil
                }
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            current = nil
        }
    }
}

private struct LeafIDToastBanner: View {
    let item: LeafIDToastItem

    var body: some View {
        HStack(alignment: .center, spacing: LeafIDTheme.space12) {
            Image(systemName: item.kind == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(item.kind == .success ? LeafIDTheme.primary : Color.orange.opacity(0.95))
            Text(item.message)
                .font(LeafIDFont.manrope(size: 14, weight: .semibold))
                .foregroundStyle(LeafIDTheme.onSurface)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LeafIDTheme.space16)
        .padding(.vertical, LeafIDTheme.space14)
        .background {
            RoundedRectangle(cornerRadius: LeafIDTheme.space16, style: .continuous)
                .fill(LeafIDTheme.surfaceContainerHigh)
        }
        .overlay {
            RoundedRectangle(cornerRadius: LeafIDTheme.space16, style: .continuous)
                .strokeBorder(LeafIDTheme.outlineVariant.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.35), radius: 20, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

struct LeafIDToastHostModifier: ViewModifier {
    @ObservedObject private var center = ToastCenter.shared

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let item = center.current {
                LeafIDToastBanner(item: item)
                    .padding(.horizontal, LeafIDTheme.screenHorizontalPadding)
                    .padding(.top, LeafIDTheme.space8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: center.current?.id)
    }
}

extension View {
    func leafIDToastHost() -> some View {
        modifier(LeafIDToastHostModifier())
    }
}
