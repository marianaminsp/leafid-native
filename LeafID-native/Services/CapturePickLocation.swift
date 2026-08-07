//
//  CapturePickLocation.swift
//  LeafID-native
//
//  Shared GPS + reverse-geocoded locality for camera capture (Supabase `latitude` / `longitude` / `locality`).
//

import CoreLocation
import Foundation

#if canImport(CoreLocation)
enum CapturePickLocationEngine {
    @MainActor
    static func coordinateAndLocality(
        exifCoordinate: CLLocationCoordinate2D?,
        useDeviceFallback: Bool
    ) async -> (CLLocationCoordinate2D?, String?) {
        if let c = exifCoordinate, CLLocationCoordinate2DIsValid(c) {
            let city = await reverseLocalityFromCoordinate(latitude: c.latitude, longitude: c.longitude)
            return (c, city)
        }
        guard useDeviceFallback else { return (nil, nil) }
        // Best-effort GPS tag during capture — shouldn't leave the user staring at "Analyzing…"
        // waiting on a permission dialog. A scan without a coordinate still saves fine; it just
        // won't show a pin on Arboretum.
        return await OneShotLocationRequest().requestCoordinateAndLocality(
            fixWaitSeconds: 3,
            authorizationWaitSeconds: 4
        )
    }
}

func reverseLocalityFromCoordinate(latitude: Double, longitude: Double) async -> String? {
    await withCheckedContinuation { continuation in
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemarks, _ in
            let resolved: String? = {
                guard let p = placemarks?.first else { return nil }
                if let s = p.locality?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { return s }
                if let s = p.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { return s }
                return nil
            }()
            continuation.resume(returning: resolved)
        }
    }
}

@MainActor
final class OneShotLocationRequest: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<(CLLocationCoordinate2D?, String?), Never>?
    private var timeoutTask: Task<Void, Never>?
    private var fixWaitSeconds: TimeInterval = 8

    /// `fixWaitSeconds`: how long to wait for an actual GPS fix once we have permission — CoreLocation's
    /// first fix after a cold start commonly takes longer than the old flat 3s budget allowed.
    /// `authorizationWaitSeconds`: how long to wait for the user to respond to the system permission
    /// dialog itself — must be generous, since reading + tapping "Allow Once" reliably takes longer than
    /// the old code gave it, which meant we gave up before the user could even answer.
    func requestCoordinateAndLocality(
        fixWaitSeconds: TimeInterval = 8,
        authorizationWaitSeconds: TimeInterval = 60
    ) async -> (CLLocationCoordinate2D?, String?) {
        await withCheckedContinuation { cont in
            continuation = cont
            self.fixWaitSeconds = fixWaitSeconds
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
                startTimeout(fixWaitSeconds)
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
                // Waiting on the user, not on GPS — the fix-acquisition timeout starts separately
                // once locationManagerDidChangeAuthorization sees an actual answer.
                startTimeout(authorizationWaitSeconds)
            case .denied, .restricted:
                finish((nil, nil))
            @unknown default:
                finish((nil, nil))
            }
        }
    }

    private func startTimeout(_ seconds: TimeInterval) {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            let ns = UInt64(seconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.finish((nil, nil)) }
        }
    }

    private func finish(_ value: (CLLocationCoordinate2D?, String?)) {
        timeoutTask?.cancel()
        timeoutTask = nil
        manager.delegate = nil
        guard let c = continuation else { return }
        continuation = nil
        c.resume(returning: value)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
                startTimeout(fixWaitSeconds)
            case .denied, .restricted:
                finish((nil, nil))
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            Task { @MainActor [weak self] in self?.finish((nil, nil)) }
            return
        }
        let coord = loc.coordinate
        guard CLLocationCoordinate2DIsValid(coord) else {
            Task { @MainActor [weak self] in self?.finish((nil, nil)) }
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let city = await reverseLocalityFromCoordinate(latitude: coord.latitude, longitude: coord.longitude)
            finish((coord, city))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in self?.finish((nil, nil)) }
    }
}
#endif
