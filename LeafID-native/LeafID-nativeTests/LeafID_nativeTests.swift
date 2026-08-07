//
//  LeafID_nativeTests.swift
//  LeafID-nativeTests
//

import XCTest
import SwiftUI
@testable import LeafID_native

final class LeafID_nativeTests: XCTestCase {

    // MARK: - ProfileStatsLocalStore

    func testScansForFreeTierGateUsesTheHigherOfTheTwoCounts() {
        XCTAssertEqual(ProfileStatsLocalStore.scansForFreeTierGate(appStorageQuota: 0), ProfileStatsLocalStore.totalScans)
        XCTAssertEqual(
            ProfileStatsLocalStore.scansForFreeTierGate(appStorageQuota: ProfileStatsLocalStore.totalScans + 5),
            ProfileStatsLocalStore.totalScans + 5
        )
    }

    // MARK: - BotanyService pure helpers

    func testIsWeakCaptureLocationStringRecognizesKnownWeakValues() {
        XCTAssertTrue(BotanyService.isWeakCaptureLocationString(""))
        XCTAssertTrue(BotanyService.isWeakCaptureLocationString("  "))
        XCTAssertTrue(BotanyService.isWeakCaptureLocationString("—"))
        XCTAssertTrue(BotanyService.isWeakCaptureLocationString("Unknown"))
        XCTAssertTrue(BotanyService.isWeakCaptureLocationString("Origin not provided"))
        XCTAssertTrue(BotanyService.isWeakCaptureLocationString("HTTP 500 error"))
        XCTAssertFalse(BotanyService.isWeakCaptureLocationString("Rio de Janeiro, Brazil"))
    }

    func testDisplaySafeLocationFallsBackOnWeakInput() {
        XCTAssertEqual(BotanyService.displaySafeLocation(nil), "Origin unavailable")
        XCTAssertEqual(BotanyService.displaySafeLocation("unknown"), "Origin unavailable")
        XCTAssertEqual(BotanyService.displaySafeLocation("Rio de Janeiro, Brazil"), "Rio de Janeiro, Brazil")
    }

    func testDisplaySafeOriginFallsBackOnWeakInput() {
        XCTAssertEqual(BotanyService.displaySafeOrigin(""), "Origin unavailable")
        XCTAssertEqual(BotanyService.displaySafeOrigin("Peru"), "Peru")
    }

    func testFormatCardinalGPSFormatsAllFourHemispheres() {
        XCTAssertEqual(BotanyService.formatCardinalGPS(latitude: -3.10, longitude: -60.02), "S 3.1000° · W 60.0200°")
        XCTAssertEqual(BotanyService.formatCardinalGPS(latitude: 51.5, longitude: 0.12), "N 51.5000° · E 0.1200°")
    }

    func testCleanBase64StripsDataURIPrefix() {
        XCTAssertEqual(BotanyService.cleanBase64("data:image/jpeg;base64,AAAA"), "AAAA")
        XCTAssertEqual(BotanyService.cleanBase64("AAAA"), "AAAA")
    }

    // MARK: - Color(hex:)

    func testColorHexRoundTripsThroughSRGBComponents() {
        let color = Color(hex: 0x93BC10)
        #if canImport(UIKit)
        let components = UIColor(color).cgColor.components ?? []
        XCTAssertEqual(components.count, 4)
        XCTAssertEqual(components[0], Double(0x93) / 255.0, accuracy: 0.01)
        XCTAssertEqual(components[1], Double(0xBC) / 255.0, accuracy: 0.01)
        XCTAssertEqual(components[2], Double(0x10) / 255.0, accuracy: 0.01)
        #endif
    }

    // MARK: - KeychainTokenStore

    func testKeychainTokenStoreRoundTripsSetGetDelete() {
        let key = "test.keychain.round_trip.\(UUID().uuidString)"
        defer { KeychainTokenStore.removeObject(forKey: key) }

        XCTAssertNil(KeychainTokenStore.string(forKey: key))

        KeychainTokenStore.set("token-value-1", forKey: key)
        XCTAssertEqual(KeychainTokenStore.string(forKey: key), "token-value-1")

        // Overwriting an existing key should replace, not duplicate/fail.
        KeychainTokenStore.set("token-value-2", forKey: key)
        XCTAssertEqual(KeychainTokenStore.string(forKey: key), "token-value-2")

        KeychainTokenStore.removeObject(forKey: key)
        XCTAssertNil(KeychainTokenStore.string(forKey: key))
    }
}
