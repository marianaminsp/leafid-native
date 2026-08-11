//
//  AppMonitoring.swift
//  LeafID-native
//
//  Analytics (PostHog) + crash/error monitoring (Sentry) setup.
//

import Foundation
import PostHog
import Sentry

enum AppMonitoring {
    /// Call once, as early as possible in app startup.
    static func configure() {
        if let apiKey = postHogAPIKey(), let host = postHogHost() {
            let config = PostHogConfig(apiKey: apiKey, host: host)
            PostHogSDK.shared.setup(config)
        }

        if let dsn = sentryDSN() {
            SentrySDK.start { options in
                options.dsn = dsn
                options.debug = false
            }
        }
    }

    /// Same quoting/placeholder guards as `AuthViewModel.supabaseAnonKey()` for values coming from Secrets.local.xcconfig.
    private static func plistString(forKey key: String) -> String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String
        var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
            value = String(value.dropFirst().dropLast())
        }
        guard !value.isEmpty, !value.contains("$(") else { return nil }
        return value
    }

    private static func postHogAPIKey() -> String? {
        plistString(forKey: "POSTHOG_API_KEY")
    }

    private static func postHogHost() -> String? {
        guard let value = plistString(forKey: "POSTHOG_HOST"), value.hasPrefix("http"),
              let host = URL(string: value)?.host, host.contains(".")
        else { return nil }
        return value
    }

    private static func sentryDSN() -> String? {
        guard let value = plistString(forKey: "SENTRY_DSN"), value.hasPrefix("http"),
              let host = URL(string: value)?.host, host.contains(".")
        else { return nil }
        return value
    }
}
