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
    let latitude: Double?
    let longitude: Double?
    /// City / locality from device `CLLocationManager` + reverse geocode at capture time (camera), when available.
    let locality: String?

    init(jpegData: Data, latitude: Double? = nil, longitude: Double? = nil, locality: String? = nil) {
        self.id = UUID()
        self.jpegData = jpegData
        self.latitude = latitude
        self.longitude = longitude
        self.locality = locality
    }
}
