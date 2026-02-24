//
//  CloudsView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import SwiftUI
import SwiftData

struct CloudsView: View {
    @Environment(\.modelContext) var context
    @Environment(CanvasProcessor.self) var processor

    @Query(sort: \Canvas.createdOn, order: .reverse)
    private var allCanvases: [Canvas]

    @Query(sort: \Cloud.createdOn, order: .reverse)
    private var clouds: [Cloud]

    private var unassigned: [Canvas] {
        allCanvases.filter { $0.cloud == nil }
    }

    @State private var path = NavigationPath()

    @Namespace private var namespace
    @State private var showSettings = false


    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
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

                    // unassigned
                    if !unassigned.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(unassigned) { canvas in
                                        UnassignedCanvasCard(canvas: canvas, isAvailable: processor.isModelAvailable)
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

                    if unassigned.isEmpty && clouds.isEmpty {
                        ContentUnavailableView(
                            "No canvases yet",
                            systemImage: "cloud",
                            description: Text("Tap + to create a canvas.")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }

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
                .padding(.vertical)
            }
            .navigationTitle("Fog")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .matchedTransitionSource(id: "settings", in: namespace)
                }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        let newCanvas = Canvas()
                        context.insert(newCanvas)
                        path.append(newCanvas)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .matchedTransitionSource(id: "createCanvas", in: namespace)
                    .buttonStyle(.glassProminent)
                }
            }
            .modifier(FogNavigationDestinations(namespace: namespace))
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .navigationTransition(.zoom(sourceID: "settings", in: namespace))
            }
        }
        .task {
            processor.prewarm()
        }
        .onAppear {
            processor.checkAvailability()
        }
    }
}

private struct UnassignedCanvasCard: View {
    let canvas: Canvas
    let isAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isAvailable {
            
                Text(canvas.title ?? "Processing...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .redacted(reason: canvas.title == nil ? .placeholder : [])
            }

            Text(canvas.text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer()

            Text(canvas.createdOn, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(width: 160, alignment: .leading)
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

#Preview(traits: .mockData) {
    CloudsView()
        .environment(CanvasProcessor())
}

