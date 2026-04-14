//
//  ProfileViewModel.swift
//  LeafID-native
//
//  Profile stats + Recent Discoveries; sync targets `profiles` + `profile_activities` (see migration 20260412_0003).
//

import Combine
import Foundation

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
        roleTitle = UserDefaults.standard.string(forKey: Self.roleTitleKey) ?? "Botanical Enthusiast"
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

    private static let greenhouseGuruID = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!

    /// Local feed until `profile_activities` is loaded from Supabase; merges a simple achievement with Herbarium-derived rows.
    func profileFeed(from herbarium: HerbariumViewModel, limit: Int = 12) -> [ProfileFeedItem] {
        var rows: [ProfileFeedItem] = []
        if plantsCount(from: herbarium) >= 1 {
            rows.append(
                ProfileFeedItem(
                    id: Self.greenhouseGuruID,
                    title: "Greenhouse Guru",
                    subtitle: "Achievement unlocked.",
                    isAchievement: true
                )
            )
        }
        for item in recentDiscoveries(from: herbarium, limit: limit) {
            rows.append(
                ProfileFeedItem(id: item.id, title: item.title, subtitle: item.subtitle, isAchievement: false)
            )
        }
        return rows
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
}
