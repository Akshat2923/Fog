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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(CanvasProcessor.self) var processor

    var body: some View {
        if !hasCompletedOnboarding && allCanvases.isEmpty {
            WelcomeView(onComplete: { hasCompletedOnboarding = true })
        } else if processor.isModelAvailable {
            CloudsView()
        } else {
            CanvasLibraryView()
        }
    }
}
