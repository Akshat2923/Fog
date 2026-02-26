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
    @State private var processor = CanvasProcessor()
    @AppStorage("accentColor") private var accentColor: Color = .primary
    @AppStorage("useFullTint") private var useFullTint: Bool = false


    var body: some Scene {
        WindowGroup {
            FogTabs()
                .environment(processor)
                .accentColor(accentColor)
            // eg tint is null if user says no here keep accent as is
                .tint(useFullTint ? accentColor : nil)  // nil = no tint override
        }
        .modelContainer(for: Canvas.self)
    }
}
