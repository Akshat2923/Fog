//
//  CloudsView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import SwiftUI
import SwiftData

struct CloudsView: View {
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
    
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                MeshGradientBackground()
                
                VStack{
                    if (selected == 0) {
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
                                                        showTitle: processor.isModelAvailable
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
                                if !processor.cloudGroups.isEmpty {
                                    ForEach(processor.cloudGroups) { group in
                                        VStack(alignment: .leading, spacing: 10) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(group.name ?? group.sharedTags.prefix(3).joined(separator: " · "))
                                                    .font(.headline)
                                                    .redacted(reason: group.name == nil ? .placeholder : [])
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
                                                .padding(.horizontal)                                        }
                                    }
                                }
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
                    } else {
                        GraphView(canvases: allCanvases, clouds: clouds, cloudGroups: processor.cloudGroups)
                            .toolbar(.hidden, for: .tabBar)
                        
                    }
                }
            }
            
            .navigationTitle(selected == 0 ? "Summary" : "Graph")
            .toolbarTitleDisplayMode(.inline)
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("View Mode", selection: $selected) {
                        Image(systemName: "rectangle.3.group").tag(0)
                        Image(systemName: "graph.3d").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Toggle view mode")
                }
                .sharedBackgroundVisibility(.hidden)
                
                
                ToolbarItem(placement: .topBarTrailing) {
                    if (processor.isProcessing){
                        ProgressView()
                        
                    } else {
                        Menu("Actions", systemImage: "bubbles.and.sparkles") {
                            Button("Rebuild Clouds? May take a moment.", systemImage: "bubbles.and.sparkles") {
                                Task {
                                    await processor.rebuildClouds(context: context)
                                }
                            }
                        }
                    }
                }
                
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                
            }
            
            .fogToolBar(namespace: namespace, path: $path)
            
            .modifier(FogNavigationDestinations(namespace: namespace, path: $path))
        }
        .task {
            processor.prewarm()
        }
        .task(id: cloudGroupTrigger) {
            await processor.buildCloudGroups(from: clouds)
        }
        
    }
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

        /// Groups clouds into rows: wide cards get their own row,
        /// small/regular cards are paired.
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

