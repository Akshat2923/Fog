//
//  SearchVIew.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/2/26.
//

import SwiftUI
import SwiftData

// Can safely delete later
struct SearchView: View {
    @Query(sort: \Canvas.updatedOn, order: .reverse) private var allCanvases: [Canvas]
    @State private var query = ""
    @State private var path = NavigationPath()
    @Namespace private var namespace
    
    private var suggestions: [String] {
        let tagCounts = allCanvases.flatMap { $0.tags }.reduce(into: [:]) { (counts: inout [String:Int], tag) in
            counts[tag, default: 0] += 1
        }
        let cloudNames = allCanvases.compactMap { $0.cloud?.name }.filter { !$0.isEmpty }
        let cloudCounts = cloudNames.reduce(into: [:]) { (counts: inout [String:Int], name) in
            counts[name, default: 0] += 1
        }
        let topTags = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        let topClouds = cloudCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        return Array((topTags + topClouds).prefix(10))
    }
    
    private var results: [Canvas] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return allCanvases.filter { canvas in
            let title = (canvas.title ?? "").lowercased()
            let text = String(canvas.text.characters).lowercased()
            let tags = canvas.tags.map { $0.lowercased() }
            let cloudName = canvas.cloud?.name.lowercased() ?? ""
            return title.contains(q)
            || text.contains(q)
            || tags.contains(where: { $0.contains(q) })
            || cloudName.contains(q)
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                MeshGradientBackground()
                ScrollView {
                    
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 1),
                        spacing: 8
                    ) {
                        if allCanvases.isEmpty {
                            Text("No canvases available. Try adding some in the 'Add' tab.")
                                .padding()
                        } else {
                            ForEach(results) { canvas in
                                NavigationLink(value: canvas) {
                                    CanvasCard(canvas: canvas)
                                }
                                .buttonStyle(.automatic)
                                .foregroundStyle(Color(.label))
                                
                            }
                            
                        }
                        
                    }
                    .padding(.horizontal, 8)
                    
                }

            }
            .navigationTitle("Search")
            .toolbarTitleDisplayMode(.inlineLarge)
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search anything")
            .scrollDismissesKeyboard(.interactively)
            .modifier(FogNavigationDestinations(namespace: namespace, path: $path))
        }
    }
}

#Preview {
    SearchView()
        .environment(CanvasProcessor())
        .modelContainer(for: Canvas.self, inMemory: true)
}
