//
//  ScanSession.swift
//  LeafID-native
//
//  Binds one picked/captured image to `fullScreenCover(item:)` so `ScannerView` always receives
//  the correct JPEG (avoids stale `pendingJPEG` when library + scanner present in the same frame).
//

import Foundation

struct ScanSession: Identifiable, Equatable {
    let id: UUID
    let jpegData: Data

    init(jpegData: Data) {
        self.id = UUID()
        self.jpegData = jpegData
    }
}
