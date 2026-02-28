//
//  CanvasLibraryView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/24/26.
//

import SwiftUI
import SwiftData

struct CanvasLibraryView: View {
    @Query(sort: \Canvas.updatedOn, order: .reverse)
    private var allCanvases: [Canvas]
        
    @State private var path = NavigationPath()
    @Namespace private var namespace
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                if allCanvases.isEmpty {
                    ContentUnavailableView(
                        "No Canvases yet",
                        systemImage: "note.text",
                        description: Text("Tap + to create one.")
                    )
                    .padding(.top, 60)
                } else {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 1),
                        spacing: 8
                    ) {
                        ForEach(allCanvases) { canvas in
                            NavigationLink(value: canvas) {
                                UnassignedCanvasCard(canvas: canvas)
                            }
                            .buttonStyle(.plain)
//                            .matchedTransitionSource(id: canvas.id, in: namespace)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .navigationTitle("Library")
            .toolbarTitleDisplayMode(.inlineLarge)
            .fogToolBar(namespace: namespace, path: $path)
            .modifier(FogNavigationDestinations(namespace: namespace, path: $path))
        }
    }
}

#Preview(traits: .mockData) {
    CanvasLibraryView()
        .environment(CanvasProcessor())
}
