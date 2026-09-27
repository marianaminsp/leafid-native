//
//  AppLogger.swift
//  LeafID-native
//
//  Centralized logging for debugging and error tracking.
//  Use this instead of print() or NSLog for better debugging visibility in Xcode.
//

import Foundation
import os

// MARK: - Logger Categories

let appLogger = Logger(subsystem: "com.leafid.native", category: "app")
let botanyLogger = Logger(subsystem: "com.leafid.native", category: "botany")
let networkLogger = Logger(subsystem: "com.leafid.native", category: "network")
let authLogger = Logger(subsystem: "com.leafid.native", category: "auth")
let uiLogger = Logger(subsystem: "com.leafid.native", category: "ui")
let storageLogger = Logger(subsystem: "com.leafid.native", category: "storage")

// MARK: - AppLog Helper for Consistent Messaging

enum AppLog {
    // MARK: - App Lifecycle

    static func appDidLaunch() {
        appLogger.info("🚀 App launched")
    }

    static func appDidEnterBackground() {
        appLogger.debug("📱 App entered background")
    }

    static func appWillEnterForeground() {
        appLogger.debug("📱 App entering foreground")
    }

    // MARK: - Botany Service

    static func identifyingPlant(fromImage imagePath: String) {
        botanyLogger.info("🌿 Identifying plant from image: \(imagePath)")
    }

    static func plantIdentified(species: String, confidence: Double) {
        botanyLogger.info("✅ Plant identified: \(species) (confidence: \(String(format: "%.1f%%", confidence * 100)))")
    }

    static func plantIdentificationFailed(_ error: Error) {
        botanyLogger.error("❌ Plant identification failed: \(error.localizedDescription)")
    }

    static func loadingPlantDetails(id: String) {
        botanyLogger.debug("📖 Loading details for plant: \(id)")
    }

    // MARK: - Network

    static func networkRequest(method: String, endpoint: String) {
        networkLogger.info("🌐 \(method) \(endpoint)")
    }

    static func networkResponse(statusCode: Int, duration: Double) {
        networkLogger.info("✓ Response: \(statusCode) (\(String(format: "%.1f", duration))ms)")
    }

    static func networkError(_ error: Error, endpoint: String) {
        networkLogger.error("❌ Network error for \(endpoint): \(error.localizedDescription)")
    }

    static func slowNetworkResponse(duration: Double, endpoint: String) {
        networkLogger.warning("⚠️ Slow response: \(String(format: "%.0f", duration))ms for \(endpoint)")
    }

    // MARK: - Authentication

    static func userLoggedIn(userID: String) {
        authLogger.info("👤 User logged in: \(userID)")
    }

    static func userLoggedOut() {
        authLogger.info("👤 User logged out")
    }

    static func authenticationFailed(_ error: Error) {
        authLogger.error("❌ Authentication failed: \(error.localizedDescription)")
    }

    static func tokenRefreshed() {
        authLogger.debug("🔄 Auth token refreshed")
    }

    // MARK: - Storage

    static func savingData(key: String) {
        storageLogger.debug("💾 Saving: \(key)")
    }

    static func loadingData(key: String) {
        storageLogger.debug("📂 Loading: \(key)")
    }

    static func storageFailed(_ error: Error, operation: String) {
        storageLogger.error("❌ Storage \(operation) failed: \(error.localizedDescription)")
    }

    // MARK: - UI

    static func navigationEvent(from: String, to: String) {
        uiLogger.debug("🔀 Navigation: \(from) → \(to)")
    }

    static func userAction(_ action: String) {
        uiLogger.debug("👆 \(action)")
    }

    static func uiRenderingIssue(_ description: String) {
        uiLogger.warning("⚠️ UI Issue: \(description)")
    }

    // MARK: - Generic Debug Logging

    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        appLogger.debug("[\(filename):\(line)] \(message)")
    }

    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        appLogger.warning("[\(filename):\(line)] ⚠️ \(message)")
    }

    static func error(_ message: String, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        appLogger.error("[\(filename):\(line)] ❌ \(message)")
    }
}

// MARK: - Xcode Console Filtering Tips

/*
 To filter logs in Xcode Console:

 1. Show all botany-related logs:
    category:"botany"

 2. Show only errors:
    level:error

 3. Show network logs:
    category:"network"

 4. Show specific subsystem:
    subsystem:"com.leafid.native"

 5. Combine filters:
    category:"botany" level:error

 Use ⌘F in the console to open the filter dialog.
 */
