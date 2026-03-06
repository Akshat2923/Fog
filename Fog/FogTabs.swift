//
//  FogTabs.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/24/26.
//

import SwiftUI
import SwiftData

struct FogTabs: View {
    @State private var selectedTab = 0
    @Environment(CanvasProcessor.self) var processor
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    
    var body: some View {
        TabView(selection: $selectedTab) {
            if processor.isModelAvailable {
                Tab("Clouds", systemImage: "smoke", value: 0) {
                    CloudsView()
                }
            }
            
            Tab("Library", systemImage: "rectangle.stack.fill", value: 1) {
                CanvasLibraryView()
            }
            Tab("Search", systemImage: "sparkle.magnifyingglass", value: 2, role: .search) {
                SearchView()
            }
            
            
        }
        .applyTabBarMinimizeBehaviorIfAvailable()
        .tabViewStyle(.sidebarAdaptable)
    }
}

private extension View {
    @ViewBuilder
    func applyTabBarMinimizeBehaviorIfAvailable() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#Preview {
    FogTabs()
        .environment(CanvasProcessor())
        .modelContainer(for: Canvas.self, inMemory: true)
}
