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

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 24) {
                VStack(alignment: .leading, spacing: 20) {

                    // Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(cloud.cloudTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.tint.opacity(0.12), in: .capsule)
                            }
                        }
                    }

                    // AI Summary
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
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))

                    // Canvas list — NavigationLink(value:) lets the parent
                    // NavigationStack handle the push via navigationDestination
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(cloud.canvases.sorted(by: { $0.createdOn > $1.createdOn })) { canvas in
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
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .matchedTransitionSource(id: canvas.id, in: namespace)
                        }
                    }
                }
                .padding()
            }
        }
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Actions", systemImage: "trash") {
                    Button("Delete Cloud? Canvas will be saved.", systemImage: "trash", role: .destructive) {
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

