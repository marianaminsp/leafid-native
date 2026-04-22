//
//  LeafID_nativeApp.swift
//  LeafID-native
//
//  Created by Mariana Minafro Spinelli on 11/04/2026.
//

import SwiftUI

@main
struct LeafID_nativeApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    handleOAuthCallback(url)
                }
        }
    }

    private func handleOAuthCallback(_ url: URL) {
        guard url.scheme?.lowercased() == "leafid", url.host?.lowercased() == "auth" else { return }

        // Google implicit/hybrid callbacks often return values in the URL fragment.
        let fragment = url.fragment ?? ""
        let query = url.query ?? ""
        let callbackPayload = [fragment, query]
            .filter { !$0.isEmpty }
            .joined(separator: "&")

        let items = callbackPayload
            .split(separator: "&")
            .map { String($0) }
            .map { pair -> (String, String) in
                let chunks = pair.split(separator: "=", maxSplits: 1).map(String.init)
                let key = chunks.first ?? ""
                let value = chunks.count > 1 ? chunks[1] : ""
                return (key, value.removingPercentEncoding ?? value)
            }

        let values = Dictionary(uniqueKeysWithValues: items)
        if values["error"] != nil {
            UserDefaults.standard.set(false, forKey: "druid.is_logged_in")
            NotificationCenter.default.post(name: .druidAuthDidChange, object: nil)
            return
        }

        if values["access_token"] != nil || values["id_token"] != nil {
            UserDefaults.standard.set(true, forKey: "druid.is_logged_in")
            if let name = values["name"], !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                UserDefaults.standard.set(name, forKey: "druid.real_name")
            }
            NotificationCenter.default.post(name: .druidAuthDidChange, object: nil)
        }
    }
}

extension Notification.Name {
    static let druidAuthDidChange = Notification.Name("druidAuthDidChange")
}
