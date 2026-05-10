//
//  ProfileViewModel.swift
//  LeafID-native
//
//  Profile stats + Recent Discoveries; sync targets `profiles` + `profile_activities` (see migration 20260412_0003).
//

import Combine
import Foundation
import SwiftUI

struct ProfileDiscoveryItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
}

/// Unified row for the Profile “Recent Discoveries” list (`docs/ui-screens/Profile.png`).
struct ProfileFeedItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let isAchievement: Bool
}

@MainActor
final class ProfileViewModel: ObservableObject {
    private static let displayNameKey = "profile.display_name"
    private static let roleTitleKey = "profile.role_title"

    @Published var displayName: String
    @Published var roleTitle: String

    init() {
        displayName = UserDefaults.standard.string(forKey: Self.displayNameKey) ?? "Elena Thorne"
        roleTitle = UserDefaults.standard.string(forKey: Self.roleTitleKey) ?? String(localized: "Botanical Enthusiast")
    }

    func persistDisplayName() {
        UserDefaults.standard.set(displayName, forKey: Self.displayNameKey)
    }

    func persistRoleTitle() {
        UserDefaults.standard.set(roleTitle, forKey: Self.roleTitleKey)
    }

    /// Specimens in Herbarium (`scans` rows).
    func plantsCount(from herbarium: HerbariumViewModel) -> Int {
        herbarium.scans.count
    }

    func distinctSpeciesCount(from herbarium: HerbariumViewModel) -> Int {
        Set(herbarium.scans.map(\.scientificName)).count
    }

    /// Lifetime identify runs (local until `profiles.lifetime_scan_count` syncs from Supabase).
    func scansCount(from herbarium: HerbariumViewModel) -> Int {
        max(ProfileStatsLocalStore.totalScans, herbarium.scans.count)
    }

    /// Collection additions derived from saved scans (`common_name` / `scientific_name` from Plant.id-backed identify → Preserve).
    func recentDiscoveries(from herbarium: HerbariumViewModel, limit: Int = 12) -> [ProfileDiscoveryItem] {
        let sorted = herbarium.scans.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        return sorted.prefix(limit).map { scan in
            ProfileDiscoveryItem(
                id: scan.id,
                title: scan.commonName,
                subtitle: "Added to collection"
            )
        }
    }

    /// Recent Herbarium saves for the Druid list (achievements live in `AchievementUnlockStore` grid).
    func collectionFeed(from herbarium: HerbariumViewModel, limit: Int = 3) -> [ProfileFeedItem] {
        recentDiscoveries(from: herbarium, limit: limit).map {
            ProfileFeedItem(id: $0.id, title: $0.title, subtitle: $0.subtitle, isAchievement: false)
        }
    }

    /// Legacy combined feed; prefer `collectionFeed` + achievements UI.
    func profileFeed(from herbarium: HerbariumViewModel, limit: Int = 12) -> [ProfileFeedItem] {
        collectionFeed(from: herbarium, limit: limit)
    }

    /// When Supabase returns rows, map them here (prepend or replace local collection lines).
    static func feedItems(from activities: [ProfileActivity]) -> [ProfileFeedItem] {
        activities.map { a in
            ProfileFeedItem(
                id: a.id,
                title: a.title,
                subtitle: a.subtitle ?? "",
                isAchievement: a.activityType == "achievement"
            )
        }
    }

    static let formatted: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    static func formatCount(_ n: Int) -> String {
        formatted.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    func mediumDate(_ date: Date) -> String {
        Self.mediumDateFormatter.string(from: date)
    }

    func colorFromHex(_ raw: String) -> Color {
        let hex = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard hex.count == 6, let int = UInt32(hex, radix: 16) else { return LeafIDTheme.primary }
        return Color(hex: int)
    }
}
