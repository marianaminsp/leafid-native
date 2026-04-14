//
//  ProfileStatsLocalStore.swift
//  LeafID-native
//
//  Local profile counters until Supabase `profiles` syncs (see `Profile.lifetimeScanCount`).
//

import Foundation

enum ProfileStatsLocalStore {
    private static let lifetimeIdentifyKey = "leafid.lifetime_identify_count"
    private static let cumulativeHerbariumSavesKey = "leafid.cumulative_herbarium_saves"
    private static let lastIdentifyAtKey = "leafid.last_identify_at"

    /// Total identify operations (demo + live `identify-plant`), persisted across launches.
    static var totalScans: Int {
        UserDefaults.standard.integer(forKey: lifetimeIdentifyKey)
    }

    static func incrementTotalScans() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: lifetimeIdentifyKey) + 1, forKey: lifetimeIdentifyKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastIdentifyAtKey)
    }

    /// Monotonic count of specimens saved to the Herbarium (cumulative, not “current list length”).
    static var cumulativeHerbariumSaves: Int {
        UserDefaults.standard.integer(forKey: cumulativeHerbariumSavesKey)
    }

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
}
