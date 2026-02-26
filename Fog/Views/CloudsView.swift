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
                    ModelUnavailableBanner()
                    
                    // unassigned
                    if !allCanvases.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(allCanvases) { canvas in
                                        UnassignedCanvasCard(canvas: canvas)
                                            .frame(width: 160)
                                            .matchedTransitionSource(id: canvas.id, in: namespace)
                                            .onTapGesture { path.append(canvas) }
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
                                    CloudCard(cloud: cloud)
                                        .matchedTransitionSource(id: cloud.id, in: namespace)
                                        .onTapGesture { path.append(cloud) }
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
            .modifier(FogNavigationDestinations(namespace: namespace))
        }
        .task {
            processor.prewarm()
        }
        .onAppear {
            processor.checkAvailability()
        }
    }
}

struct UnassignedCanvasCard: View {
    let canvas: Canvas
    @Environment(CanvasProcessor.self) private var processor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if processor.isModelAvailable {
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

private struct ModelUnavailableBanner: View {
    @Environment(CanvasProcessor.self) private var processor
    
    var body: some View {
        if !processor.isModelAvailable {
            Label(processor.notAvailableReason, systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.1), in: .rect(cornerRadius: 10))
                .padding(.horizontal)
        }
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

