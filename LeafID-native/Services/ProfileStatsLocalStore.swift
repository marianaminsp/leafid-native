//
//  ProfileStatsLocalStore.swift
//  LeafID-native
//
//  Local profile counters until Supabase `profiles` syncs (see `Profile.lifetimeScanCount`).
//

import Foundation

struct ProfileStatsSnapshot {
    let totalScans: Int
    let uniqueFamilies: Int
    let dominantColorHex: String
    let unlockedCountries: [String]
    let firstDiscoveryDate: Date?
    let discoveryStreakDays: Int
}

enum ProfileStatsLocalStore {
    private static let lifetimeIdentifyKey = "leafid.lifetime_identify_count"
    private static let cumulativeHerbariumSavesKey = "leafid.cumulative_herbarium_saves"
    private static let lastIdentifyAtKey = "leafid.last_identify_at"
    /// Shared with `AuthViewModel` / `@AppStorage("profile.scans_count")` for quota + Druid rank.
    static let profileQuotaScansKey = "profile.scans_count"

    /// Total identify operations (demo + live `identify-plant`), persisted across launches.
    static var totalScans: Int {
        UserDefaults.standard.integer(forKey: lifetimeIdentifyKey)
    }

    /// For free-scan gating: same monotonic rule as Druid (`max` of synced quota and local lifetime).
    static func scansForFreeTierGate(appStorageQuota: Int) -> Int {
        max(appStorageQuota, totalScans)
    }

    static func incrementTotalScans() {
        let defaults = UserDefaults.standard
        let next = defaults.integer(forKey: lifetimeIdentifyKey) + 1
        defaults.set(next, forKey: lifetimeIdentifyKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastIdentifyAtKey)
        let quota = defaults.integer(forKey: profileQuotaScansKey)
        defaults.set(max(quota, next), forKey: profileQuotaScansKey)
    }

    /// Bumps `profile.scans_count` when local lifetime is ahead (older builds did not mirror every identify).
    static func reconcileProfileQuotaWithLifetime() {
        let defaults = UserDefaults.standard
        let lifetime = totalScans
        let quota = defaults.integer(forKey: profileQuotaScansKey)
        guard lifetime > quota else { return }
        defaults.set(lifetime, forKey: profileQuotaScansKey)
    }

    /// Monotonic count of specimens saved to the Herbarium (cumulative, not “current list length”).
    static var cumulativeHerbariumSaves: Int {
        UserDefaults.standard.integer(forKey: cumulativeHerbariumSavesKey)
    }

    /// Incremented when Preserve completes: **cloud** insert succeeded, or Supabase is not configured (local-only dev).
    static func recordHerbariumSave() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: cumulativeHerbariumSavesKey) + 1, forKey: cumulativeHerbariumSavesKey)
    }

    static var lastIdentifyDate: Date? {
        let t = UserDefaults.standard.double(forKey: lastIdentifyAtKey)
        guard t > 0 else { return nil }
        return Date(timeIntervalSince1970: t)
    }

    // MARK: - Legacy naming (kept for call sites / migrations)

    static var lifetimeIdentifyCount: Int { totalScans }

    static func incrementLifetimeIdentifyCount() {
        incrementTotalScans()
    }

    static func snapshot(from scans: [Scan]) -> ProfileStatsSnapshot {
        let families = Set(
            scans.compactMap { $0.family?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                .filter { !$0.isEmpty && $0 != "UNCLASSIFIED" }
        )
        let countries = Array(
            Set(
                scans.compactMap {
                    $0.originCountry?.trimmingCharacters(in: .whitespacesAndNewlines)
                }.filter { !$0.isEmpty && $0 != "—" && $0.lowercased() != "origin under review" }
            )
        ).sorted()

        let paletteVotes = scans.flatMap(\.normalizedPaletteHexes)
        let dominant = dominantHexColor(from: paletteVotes) ?? "#93BC10"
        let firstDate = scans.compactMap(\.createdAt).min()
        let streak = discoveryStreakDays(from: scans.compactMap(\.createdAt))

        return ProfileStatsSnapshot(
            totalScans: max(totalScans, scans.count),
            uniqueFamilies: families.count,
            dominantColorHex: dominant,
            unlockedCountries: countries,
            firstDiscoveryDate: firstDate,
            discoveryStreakDays: streak
        )
    }

    private static func dominantHexColor(from hexes: [String]) -> String? {
        guard !hexes.isEmpty else { return nil }
        let counts = hexes.reduce(into: [String: Int]()) { partialResult, hex in
            partialResult[hex, default: 0] += 1
        }
        return counts.max { a, b in a.value < b.value }?.key
    }

    private static func discoveryStreakDays(from dates: [Date]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(dates.map { calendar.startOfDay(for: $0) })
        guard !uniqueDays.isEmpty else { return 0 }
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)
        while uniqueDays.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
