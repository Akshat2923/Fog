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
    
    @Query(sort: \Canvas.createdOn, order: .reverse)
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
    @State private var selected = 1
    
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    
                    
                    // unassigned
                    if !allCanvases.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Canvases")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(allCanvases) { canvas in
                                        NavigationLink(value: canvas) {
                                            UnassignedCanvasCard(
                                                canvas: canvas,
                                                showTitle: processor.isModelAvailable
                                            )
                                            .frame(width: 160)
                                        }
                                        .buttonStyle(.plain)
                                        .matchedTransitionSource(id: canvas.id, in: namespace)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    // ungrouped clouds
                    if !ungroupedClouds.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Clouds")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 12
                            ) {
                                ForEach(ungroupedClouds) { cloud in
                                    NavigationLink(value: cloud) {
                                        CloudCard(cloud: cloud)
                                    }
                                    .buttonStyle(.plain)
                                    .matchedTransitionSource(id: cloud.id, in: namespace)
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
                                            .lineLimit(2)
                                            .animation(.easeInOut, value: group.groupDescription)
                                    }
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(group.clouds) { cloud in
                                            NavigationLink(value: cloud) {
                                                CloudCard(cloud: cloud)
                                                    .frame(width: 180)
                                            }
                                            .buttonStyle(.plain)
                                            .matchedTransitionSource(id: cloud.id, in: namespace)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
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
                    
                    ProcessingIndicator()
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("Clouds")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker(selection: $selected, label: Text("Picker")) {
                        Label("Groups", systemImage: "rectangle.3.group").tag(0)
                        Label("Graphs", systemImage: "graph.3d").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .tint(.accentColor)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Actions", systemImage: "bubbles.and.sparkles.fill") {
                        Button("Rebuild Clouds? May take a moment.", systemImage: "bubbles.and.sparkles.fill") {
                        Task {
                            await processor.rebuildClouds(context: context)
                            await processor.buildCloudGroups(from: clouds)
                        }
                    }
                    }
                    .disabled(processor.isProcessing || !processor.isModelAvailable)
                }
            }
            .toolbarRole(.editor)

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
}

struct UnassignedCanvasCard: View {
    let canvas: Canvas
    var showTitle: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showTitle {
                Text(canvas.title ?? "Processing...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .redacted(reason: canvas.title == nil ? .placeholder : [])
                    .animation(.easeInOut, value: canvas.title)
            }
            
            Text(String(canvas.text.characters.prefix(200)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            Spacer()
            
            Text(canvas.createdOn, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }
}

private struct CloudCard: View {
    let cloud: Cloud
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(cloud.canvases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(cloud.name.isEmpty ? "New Cloud" : cloud.name)
                .font(.headline)
                .lineLimit(2)
                .redacted(reason: cloud.name.isEmpty ? .placeholder : [])
                .animation(.easeInOut, value: cloud.name)
            if !cloud.cloudTags.isEmpty {
                Text(cloud.cloudTags.prefix(3).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 130)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }
}


private struct ProcessingIndicator: View {
    @Environment(CanvasProcessor.self) private var processor
    
    var body: some View {
        if processor.isProcessing {
            HStack {
                ProgressView()
                Text("Organizing your note...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
}

#Preview(traits: .mockData) {
    CloudsView()
        .environment(CanvasProcessor())
}

