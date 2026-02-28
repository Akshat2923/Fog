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
    
    @Query(sort: \Canvas.createdOn, order: .reverse)
    private var allCanvases: [Canvas]
    
    @Query(sort: \Cloud.createdOn, order: .reverse)
    private var clouds: [Cloud]
    
    // this change only shows canvas that were not in a cloud
    //    private var unassigned: [Canvas] {
    //        allCanvases.filter { $0.cloud == nil }
    //    }
    
    @State private var path = NavigationPath()
    
    @Namespace private var namespace
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    
                    // unassigned
                    if !allCanvases.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent")
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
//                                        .matchedTransitionSource(id: canvas.id, in: namespace)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // clouds
                    if !clouds.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Clouds")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 12
                            ) {
                                ForEach(clouds) { cloud in
                                    NavigationLink(value: cloud) {
                                        CloudCard(cloud: cloud)
                                    }
                                    .buttonStyle(.plain)
//                                    .matchedTransitionSource(id: cloud.id, in: namespace)
                                }
                            }
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
                    
                    ProcessingIndicator()
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("Fog")
            .toolbarTitleDisplayMode(.inlineLarge)
            .fogToolBar(namespace: namespace, path: $path)
            .modifier(FogNavigationDestinations(namespace: namespace, path: $path))
        }
        .task {
            processor.prewarm()
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
            Text(cloud.name)
                .font(.headline)
                .lineLimit(2)
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
                Text("Canvas is searching for a Cloud...")
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

