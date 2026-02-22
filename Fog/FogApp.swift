//
//  FogApp.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/21/26.
//

import SwiftUI
import SwiftData

@main
struct FogApp: App {
    var body: some Scene {
        WindowGroup {
            FogTabs()
        }
        .modelContainer(for: Canvas.self)
    }
}
