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

    var body: some Scene {
        WindowGroup {
            CloudsView()
                .environment(processor)
        }
        .modelContainer(for: Canvas.self)
    }
}
