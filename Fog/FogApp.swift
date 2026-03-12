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
    @State private var pileManager = PileManager()
    @State private var showingAlert = false

    var body: some Scene {
        WindowGroup {
            FogRootView()
                .environment(processor)
                .environment(pileManager)
                // Theme driven by the active pile; fall back to system defaults
                .accentColor(pileManager.activePile?.accentColor ?? .primary)
                .tint((pileManager.activePile?.useFullTint ?? false) ? (pileManager.activePile?.accentColor ?? .primary) : nil)
                .alert("Important message", isPresented: $showingAlert) {
                    Button("OK", role: .confirm) { }
                } message: {
                    Text(processor.notAvailableReason)
                }
                .onAppear {
                    showingAlert = !processor.isModelAvailable
                }
                .alert(
                    "Couldn't Complete AI Action",
                    isPresented: Binding(
                        get: { processor.userFacingErrorMessage != nil },
                        set: { isPresented in
                            if !isPresented {
                                processor.clearUserFacingError()
                            }
                        }
                    )
                ) {
                    Button("OK", role: .cancel) {
                        processor.clearUserFacingError()
                    }
                } message: {
                    Text(processor.userFacingErrorMessage ?? "An unknown error occurred.")
                }
        }
        // Canvas.self is the root; SwiftData infers Cloud and Pile via relationships
        .modelContainer(for: Canvas.self)
    }
}
