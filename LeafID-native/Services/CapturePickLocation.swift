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
        return await OneShotLocationRequest().requestCoordinateAndLocality()
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

    func requestCoordinateAndLocality(maxWaitSeconds: TimeInterval = 3) async -> (CLLocationCoordinate2D?, String?) {
        await withCheckedContinuation { cont in
            continuation = cont
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                finish((nil, nil))
            @unknown default:
                finish((nil, nil))
            }

            timeoutTask = Task { [weak self] in
                let ns = UInt64(maxWaitSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
                await MainActor.run { self?.finish((nil, nil)) }
            }
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
