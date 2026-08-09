//
//  RedesignPrototypeState.swift
//  LeafID-native
//
//  One shared empty/populated flag for the whole redesign prototype, not four independent
//  per-screen toggles. Identify, Herbarium, and Druid all read `hasDiscoveries` from here.
//  The single trigger that flips it is tapping "Save to Herbarium" on the Scanner's Reveal
//  card — a UI-only state flip for this prototype pass, not a call to
//  BotanyService.saveUserCapture, consistent with every other mocked action in the redesign.
//  Injected via `.environmentObject()` from `NeoBrutalistAppRoot`.
//

import SwiftUI

final class RedesignPrototypeState: ObservableObject {
    @Published var hasDiscoveries = false
}
