//
//  DruidProfileViewModel.swift
//  LeafID-native
//
//  Supabase-backed profile + stats (protocol Tab 4). Wire REST/Realtime when client lands.
//

import Combine
import Foundation

@MainActor
final class DruidProfileViewModel: ObservableObject {
    @Published private(set) var profile: Profile?
    @Published private(set) var specimenCount: Int = 0
    @Published private(set) var ancientSeedsCount: Int = 0
    @Published private(set) var isLoading = true
    @Published var lastError: String?

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        // Placeholder: replace with Supabase `profiles` + aggregates.
        try? await Task.sleep(nanoseconds: 350_000_000)
        profile = Profile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            displayName: "The Druid",
            bio: """
            Field botanist at heart — collecting ancient seeds one walk at a time. \
            The Herbarium is my journal; the Arboretum, my map of wonder.
            """,
            avatarURL: nil,
            ancientSeedsCount: 12
        )
        specimenCount = 42
        ancientSeedsCount = profile?.ancientSeedsCount ?? 0
    }
}
