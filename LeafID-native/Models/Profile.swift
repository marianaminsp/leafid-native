//
//  Profile.swift
//  LeafID-native
//
//  RLS: `public.profiles` keyed by `id` = `auth.uid()` (see 20260410_0001_rls_baseline.sql).
//  Column set is not fully defined in repo migrations — confirm against your live Supabase schema.
//

import Foundation

struct Profile: Identifiable, Codable, Equatable {
    var id: UUID
    var displayName: String?
    var bio: String?
    var avatarURL: String?
    /// Subtitle under display name (`20260412_0003_profile_role_activities.sql`).
    var roleTitle: String?
    /// Total identify runs; mirror `ProfileStatsLocalStore` until client syncs.
    var lifetimeScanCount: Int?
    /// Extend when your `profiles` table adds gamification columns
    var ancientSeedsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case bio
        case avatarURL = "avatar_url"
        case roleTitle = "role_title"
        case lifetimeScanCount = "lifetime_scan_count"
        case ancientSeedsCount = "ancient_seeds_count"
    }
}

// MARK: - `profile_activities` (Supabase `20260412_0003_profile_role_activities.sql`)

/// Server feed row for Profile “Recent Discoveries”. Wire REST when the Swift client selects from `profile_activities`.
struct ProfileActivity: Identifiable, Codable, Equatable {
    var id: UUID
    var userId: UUID
    /// `achievement` | `collection_add`
    var activityType: String
    var title: String
    var subtitle: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityType = "activity_type"
        case title
        case subtitle
        case createdAt = "created_at"
    }
}
