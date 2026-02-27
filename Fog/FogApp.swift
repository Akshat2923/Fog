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
    @State private var showingAlert = false

    var body: some Scene {
        WindowGroup {
            FogTabs()
                .environment(processor)
                .accentColor(accentColor)
            // eg tint is null if user says no here keep accent as is
                .tint(useFullTint ? accentColor : nil)
                .alert("Important message", isPresented: $showingAlert) {
                    Button("OK", role: .confirm) { }
                } message: {
                    Text(processor.notAvailableReason)
                }
                .onAppear {
                    showingAlert = !processor.isModelAvailable
                }

        }
        .modelContainer(for: Canvas.self)
    }
}
