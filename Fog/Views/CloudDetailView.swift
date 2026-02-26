//
//  CloudDetailView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import SwiftUI
import SwiftData

struct CloudDetailView: View {
    let cloud: Cloud
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    
    // Namespace passed from CloudsView so canvas card zoom transitions work
    let namespace: Namespace.ID
    @Environment(CanvasProcessor.self) var processor
    @State private var showDeleteConfirm = false
    
    private var sortedCanvases: [Canvas] {
        cloud.canvases.sorted { $0.createdOn > $1.createdOn }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(cloud.cloudTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .glassEffect(.regular.tint(.teal.opacity(0.4)))
                        }
                    }
                }
                
                // AI Summary
                StreamingSummarySection()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Canvases")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ForEach(sortedCanvases) { canvas in
                        NavigationLink(value: canvas) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(canvas.title ?? "Untitled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .redacted(reason: canvas.title == nil ? .placeholder : [])
                                
                                Text(canvas.text)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                
                                Text(canvas.updatedOn, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: canvas.id, in: namespace)
                    }
                }
            }
            .padding()
            
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Actions", systemImage: "trash") {
                    Button("Delete Cloud? Canvases are saved.", systemImage: "trash", role: .destructive) {
                        context.delete(cloud)
                        dismiss()
                    }
                }
                .menuIndicator(.hidden)
            }
        }
        
        .navigationTitle(cloud.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await processor.streamSummary(for: cloud)
        }
    }
}

private struct StreamingSummarySection: View {
    @Environment(CanvasProcessor.self) private var processor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Summary", systemImage: "sparkles")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if processor.isStreamingSummary && processor.streamingSummary.isEmpty {
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Generating summary...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !processor.streamingSummary.isEmpty {
                Text(processor.streamingSummary)
                    .font(.body)
                    .animation(.easeInOut, value: processor.streamingSummary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//#Preview(traits: .mockData) {
//    // @Previewable @Query gives us live SwiftData objects in previews
//    Previewable @Query var clouds: [Cloud]
//
//    struct PreviewHost: View {
//        let cloud: Cloud
//        @Namespace var ns
//        var body: some View {
//            CloudDetailView(cloud: cloud, namespace: ns)
//                .environment(CanvasProcessor())
//        }
//    }
//
//    if let first = clouds.first {
//        PreviewHost(cloud: first)
//    }
//}

