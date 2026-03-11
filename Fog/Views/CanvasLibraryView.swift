//
//  CanvasLibraryView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/24/26.
//

import SwiftUI
import SwiftData

// This is purely a view for devices that don't support Apple Intelligence
struct CanvasLibraryView: View {
    @Query(sort: \Canvas.updatedOn, order: .reverse)
    private var allCanvases: [Canvas]
    
    @State private var path = NavigationPath()
    @Namespace private var namespace
    @State private var sortOrder: CanvasSortOrder = .updatedNewest
    
    private var sortedCanvases: [Canvas] {
        switch sortOrder {
        case .updatedNewest: return allCanvases.sorted { $0.updatedOn > $1.updatedOn }
        case .updatedOldest: return allCanvases.sorted { $0.updatedOn < $1.updatedOn }
        case .createdNewest: return allCanvases.sorted { $0.createdOn > $1.createdOn }
        case .createdOldest: return allCanvases.sorted { $0.createdOn < $1.createdOn }
        }
    }
    
    @State private var query = ""
    private var results: [Canvas] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return allCanvases.filter { canvas in
            let text = String(canvas.text.characters).lowercased()
            return text.contains(q)
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                MeshGradientBackground()
                
                SearchAwareContent(
                    allCanvases: allCanvases,
                    sortedCanvases: sortedCanvases,
                    
                    results: results,
                )
            }
            .searchable(text: $query)
            .navigationTitle("Canvas Library")
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            .fogToolBar(namespace: namespace, path: $path, filterByCanvases: .constant(true), sortOrder: $sortOrder)
            .modifier(FogNavigationDestinations(namespace: namespace, path: $path))
        }
    }
    private struct SearchAwareContent: View {
        @Environment(\.isSearching) private var isSearching
        
        let allCanvases: [Canvas]
        let sortedCanvases: [Canvas]
        
        let results: [Canvas]
        
        var body: some View {
            if !isSearching {
                // Render CanvasLibraryView inline, or replicate its grid here
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                        ForEach(sortedCanvases) { canvas in
                            NavigationLink(value: canvas) {
                                CanvasCard(canvas: canvas)
                            }
                            .buttonStyle(.automatic)
                            .foregroundStyle(Color(.label))
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                        ForEach(results) { canvas in
                            NavigationLink(value: canvas) {
                                CanvasCard(canvas: canvas)
                            }
                            .buttonStyle(.automatic)
                            .foregroundStyle(Color(.label))
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }
}

#Preview(traits: .mockData) {
    CanvasLibraryView()
        .environment(CanvasProcessor())
}
