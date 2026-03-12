//
//  FogRootView.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/7/26.
//

import SwiftUI
import SwiftData

struct FogRootView: View {
    @Query(sort: \Canvas.updatedOn, order: .reverse) private var allCanvases: [Canvas]
    @Query(sort: \Pile.createdOn, order: .forward) private var allPiles: [Pile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(CanvasProcessor.self) var processor
    @Environment(PileManager.self) var pileManager
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if !hasCompletedOnboarding && allCanvases.isEmpty {
                WelcomeView(onComplete: { hasCompletedOnboarding = true })
            } else if processor.isModelAvailable {
                CloudsView()
            } else {
                CanvasLibraryView()
            }
        }
        .onAppear {
            pileManager.loadActivePile(from: allPiles, context: context)
        }
        .onChange(of: allPiles) {
            // Re-sync if piles change externally (e.g. first pile created during onboarding)
            if pileManager.activePile == nil {
                pileManager.loadActivePile(from: allPiles, context: context)
            }
        }
    }
}
