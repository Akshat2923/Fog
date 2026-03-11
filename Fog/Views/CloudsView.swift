//
//  CloudsView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import SwiftUI
import SwiftData

struct CloudsView: View {
    // search
    @State private var query = ""
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
    
    @Environment(CanvasProcessor.self) var processor
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Canvas.updatedOn, order: .reverse)
    private var allCanvases: [Canvas]
    
    @Query(sort: \Cloud.createdOn, order: .reverse)
    private var clouds: [Cloud]
    
    private var ungroupedClouds: [Cloud] {
        let grouped = Set(processor.cloudGroups.flatMap(\.clouds))
        return clouds.filter { !grouped.contains($0) }
    }
    
    private var cloudGroupTrigger: Int {
        var hasher = Hasher()
        for cloud in clouds {
            hasher.combine(cloud.name)
            hasher.combine(cloud.cloudTags)
        }
        return hasher.finalize()
    }
    
    @State private var path = NavigationPath()
    
    @Namespace private var namespace
    @State private var selected = 0
    
    // canvas lib
    @State private var filterByCanvases = false
    @State private var sortOrder: CanvasSortOrder = .updatedNewest
    
    private var sortedCanvases: [Canvas] {
        switch sortOrder {
        case .updatedNewest: return allCanvases.sorted { $0.updatedOn > $1.updatedOn }
        case .updatedOldest: return allCanvases.sorted { $0.updatedOn < $1.updatedOn }
        case .createdNewest: return allCanvases.sorted { $0.createdOn > $1.createdOn }
        case .createdOldest: return allCanvases.sorted { $0.createdOn < $1.createdOn }
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                MeshGradientBackground()
                
                VStack{
                    SearchAwareContent(
                        allCanvases: allCanvases,
                        sortedCanvases: sortedCanvases,
                        
                        results: results,
                        clouds: clouds,
                        ungroupedClouds: ungroupedClouds,
                        cloudGroups: processor.cloudGroups,
                        namespace: namespace,
                        filterByCanvases: filterByCanvases,
                        path: $path
                    )
                    //                    if (selected == 0) {
                    //                        SearchAwareContent(
                    //                            allCanvases: allCanvases,
                    //                            results: results,
                    //                            clouds: clouds,
                    //                            ungroupedClouds: ungroupedClouds,
                    //                            cloudGroups: processor.cloudGroups,
                    //                            isModelAvailable: processor.isModelAvailable,
                    //                            namespace: namespace,
                    //                            path: $path
                    //                        )
                    //                    } else {
                    //                        GraphView(canvases: allCanvases, clouds: clouds, cloudGroups: processor.cloudGroups)
                    //                            .toolbar(.hidden, for: .tabBar)
                    //
                    //                    }
                }
            }
            
            .navigationTitle(filterByCanvases ? "Canvases" : "Summary")
            //            .toolbarTitleDisplayMode(.inlineLarge)
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            .toolbar {
                
                //                ToolbarItem(placement: .topBarTrailing) {
                //                    Picker("View Mode", selection: $selected) {
                //                        Image(systemName: "rectangle.3.group").tag(0)
                //                        Image(systemName: "graph.3d").tag(1)
                //                    }
                //                    .pickerStyle(.segmented)
                //                    .accessibilityLabel("Toggle view mode")
                //                }
                //                .sharedBackgroundVisibility(.hidden)
                
                ToolbarItem(placement: .topBarLeading) {
                    if (processor.isProcessing){
                        ProgressView()
                        
                    } else {
                        Menu("Rebuild Clouds", systemImage: "bubbles.and.sparkles") {
                            Menu("Rebuild Clouds?", systemImage: "bubbles.and.sparkles") {
                                Button("This will delete your current clouds.", role: .destructive) {
                                    Task {
                                        await processor.rebuildClouds(context: context)
                                    }
                                }
                            }
                        }
                    }
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
            }
            .searchable(text: $query)
            
            .fogToolBar(namespace: namespace, path: $path, filterByCanvases: $filterByCanvases, sortOrder: $sortOrder)
            .modifier(FogNavigationDestinations(namespace: namespace, path: $path))
        }
        .task {
            processor.prewarm()
        }
        .task(id: cloudGroupTrigger) {
            await processor.buildCloudGroups(from: clouds)
        }
        
    }
    
    // Main content need to clean up
    private struct SearchAwareContent: View {
        @Environment(\.isSearching) private var isSearching
        
        let allCanvases: [Canvas]
        let sortedCanvases: [Canvas]
        
        let results: [Canvas]
        let clouds: [Cloud]
        let ungroupedClouds: [Cloud]
        let cloudGroups: [CloudGroup]
        let namespace: Namespace.ID
        let filterByCanvases: Bool
        @Binding var path: NavigationPath
        
        var body: some View {
            if filterByCanvases {
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
            } else if isSearching {
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
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // unassigned
                        if !allCanvases.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Jump Back In")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 100)), GridItem(.flexible())],
                                    alignment: .center,
                                    spacing: 10
                                ) {
                                    ForEach(allCanvases.prefix(4)) { canvas in
                                        NavigationLink(value: canvas) {
                                            RecentCanvasCard(
                                                canvas: canvas,
                                            )
                                            
                                        }
                                        .buttonStyle(.automatic)
                                        .foregroundStyle(Color(.label))
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // cloud groups
                        if !cloudGroups.isEmpty {
                            ForEach(cloudGroups) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Group {
                                            if let name = group.name {
                                                Text(name)
                                                    .transition(.opacity)
                                            } else if !group.sharedTags.isEmpty {
                                                Text(group.sharedTags.prefix(3).joined(separator: " · "))
                                                    .transition(.opacity)
                                            } else {
                                                BlinkingCursor()
                                                    .transition(.opacity)
                                            }
                                        }
                                        .font(.headline)
                                        .animation(.easeInOut, value: group.name)
                                        if let desc = group.groupDescription {
                                            Text(desc)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(3)
                                                .animation(.easeInOut, value: group.groupDescription)
                                        }
                                    }
                                    .padding(.horizontal)
                                    
                                    WidgetGrid(clouds: group.clouds)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        //ungrouped
                        if !ungroupedClouds.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Clouds For You")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                WidgetGrid(clouds: ungroupedClouds)
                                    .padding(.horizontal)
                            }
                        }
                        
                        if allCanvases.isEmpty && clouds.isEmpty {
                            ContentUnavailableView(
                                "No Clouds Yet",
                                systemImage: "cloud",
                                description: Text("Tap + to create a canvas.")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        }
                        
                    }
                    
                    .padding(.vertical)
                    
                }
            }
        }
    }
    
    
    // UI Helpers
    private struct WidgetGrid: View {
        let clouds: [Cloud]
        
        var body: some View {
            // Walk clouds in order, placing wide cards as full-width rows
            // and pairing narrow cards two-per-row.
            let rows = buildRows(clouds)
            
            VStack(spacing: 10) {
                ForEach(rows.indices, id: \.self) { i in
                    let row = rows[i]
                    if row.count == 1 {
                        // Full-width: medium or large
                        NavigationLink(value: row[0]) {
                            CloudCard(cloud: row[0])
                        }
                        .buttonStyle(.automatic)
                        .foregroundStyle(Color(.label))
                    } else {
                        // Two narrow cards side by side
                        HStack(spacing: 10) {
                            ForEach(row) { cloud in
                                NavigationLink(value: cloud) {
                                    CloudCard(cloud: cloud)
                                }
                                .buttonStyle(.automatic)
                                .foregroundStyle(Color(.label))
                            }
                        }
                    }
                }
            }
        }
        
        private func buildRows(_ clouds: [Cloud]) -> [[Cloud]] {
            var rows: [[Cloud]] = []
            var pending: Cloud? = nil
            
            for cloud in clouds {
                let size = CloudWidgetSize(canvasCount: cloud.canvases.count)
                if size.isWide {
                    // Flush any waiting narrow card first
                    if let p = pending {
                        rows.append([p])
                        pending = nil
                    }
                    rows.append([cloud])
                } else {
                    if let p = pending {
                        rows.append([p, cloud])
                        pending = nil
                    } else {
                        pending = cloud
                    }
                }
            }
            
            // Flush last unpaired narrow card
            if let p = pending {
                rows.append([p])
            }
            
            return rows
        }
    }
    
}

#Preview(traits: .mockData) {
    CloudsView()
        .environment(CanvasProcessor())
}

