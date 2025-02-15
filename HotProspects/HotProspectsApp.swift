//
//  HotProspectsApp.swift
//  HotProspects
//
//  Created by Kok on 11/9/24.
//

import SwiftUI
import SwiftData

@main
struct HotProspectsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Prospect.self)
        }
    }
}
