//
//  CloudsView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import SwiftUI
import SwiftData

struct CloudsView: View {
    @State private var query = ""
    @State private var path = NavigationPath()
    @Namespace private var namespace
    @State private var filterByCanvases = false
    @State private var sortOrder: CanvasSortOrder = .updatedNewest
    
    @Environment(CanvasProcessor.self) var processor
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Canvas.updatedOn, order: .reverse) private var allCanvases: [Canvas]
    @Query(sort: \Cloud.createdOn, order: .reverse) private var clouds: [Cloud]
    
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
    
    private var sortedCanvases: [Canvas] {
        switch sortOrder {
        case .updatedNewest: return allCanvases.sorted { $0.updatedOn > $1.updatedOn }
        case .updatedOldest: return allCanvases.sorted { $0.updatedOn < $1.updatedOn }
        case .createdNewest: return allCanvases.sorted { $0.createdOn > $1.createdOn }
        case .createdOldest: return allCanvases.sorted { $0.createdOn < $1.createdOn }
        }
    }
    
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
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                MeshGradientBackground()
                ContentRouter(
                    query: query,
                    results: results,
                    allCanvases: allCanvases,
                    sortedCanvases: sortedCanvases,
                    clouds: clouds,
                    ungroupedClouds: ungroupedClouds,
                    cloudGroups: processor.cloudGroups,
                    filterByCanvases: filterByCanvases,
                    path: $path
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(filterByCanvases ? "Canvases" : "Summary")
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if processor.isProcessing {
                        ProgressView()
                    } else {
                        Menu("Rebuild Clouds", systemImage: "bubbles.and.sparkles") {
                            Menu("Rebuild Clouds?", systemImage: "bubbles.and.sparkles") {
                                Button("This will delete your current clouds.", role: .destructive) {
                                    Task { await processor.rebuildClouds(context: context) }
                                }
                            }
                        }
                    }
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            .searchable(text: $query, prompt: "Ask anything")
            .searchToolbarBehavior(filterByCanvases ? .minimize : .automatic)
            
            .fogToolBar(namespace: namespace, path: $path, filterByCanvases: $filterByCanvases, sortOrder: $sortOrder)
            .modifier(FogNavigationDestinations(namespace: namespace, path: $path))
        }
        .task { processor.prewarm() }
        .task(id: cloudGroupTrigger) { await processor.buildCloudGroups(from: clouds) }
        .task(id: cloudGroupTrigger) { await processor.generateGreeting(clouds: clouds, canvases: allCanvases) }
    }
}

// MARK: - Content Router

private struct ContentRouter: View {
    @Environment(\.isSearching) private var isSearching
    
    let query: String
    let results: [Canvas]
    let allCanvases: [Canvas]
    let sortedCanvases: [Canvas]
    let clouds: [Cloud]
    let ungroupedClouds: [Cloud]
    let cloudGroups: [CloudGroup]
    let filterByCanvases: Bool
    @Binding var path: NavigationPath
    
    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        ZStack {
            if isSearching && !trimmedQuery.isEmpty && results.isEmpty {
                SearchEmptyView(query: trimmedQuery, allCanvases: allCanvases)
                    .transition(.opacity)
            } else if isSearching && !trimmedQuery.isEmpty {
                SearchResultsView(results: results)
                    .transition(.opacity)
            } else if filterByCanvases {
                CanvasListView(canvases: sortedCanvases)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                SummaryView(
                    allCanvases: allCanvases,
                    clouds: clouds,
                    ungroupedClouds: ungroupedClouds,
                    cloudGroups: cloudGroups
                )
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: filterByCanvases)
    }
}

// MARK: - Search Results

private struct SearchResultsView: View {
    let results: [Canvas]
    
    var body: some View {
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

// MARK: - Search Empty (No Results + Ask)

private struct SearchEmptyView: View {
    @Environment(CanvasProcessor.self) var processor
    @Namespace private var namespace
    
    let query: String
    let allCanvases: [Canvas]
    
    // Separate bools per card, mirroring WelcomeView's showTheme / showCard0 pattern
    @State private var showEmpty:  Bool = true
    @State private var showResult: Bool = false
    
    @State private var showAnswer: Bool = false
    
    private let glassShape = RoundedRectangle(cornerRadius: 34, style: .continuous)
    
    var body: some View {
        VStack {
            GlassEffectContainer(spacing: 16) {
                ScrollView() {
                    if showEmpty {
                        
                        emptyCard
                            .glassEffect(.regular.interactive(), in: glassShape)
                            .glassEffectID("empty", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                    }
                    if showResult {
                        resultCard
                            .glassEffect(.clear.interactive(), in: glassShape)
                            .glassEffectID("result", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                    }
                    
                    
                    
                    
                    if showAnswer {
                        askAnswerCard
                            .glassEffect(.regular.interactive(), in: glassShape)
                            .glassEffectID("answer", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                    }
                    
                    
                }
                .padding(20)
                if processor.isModelAvailable {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            showEmpty = false
                            showResult = true
                            showAnswer = true
                        }
                        Task {
                            await processor.answerSearchQuery(query, canvases: allCanvases)
                        }
                    } label: {
                        Label("Ask?", systemImage: "bubbles.and.sparkles")
                    }
                    .buttonStyle(.glassProminent)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: query.isEmpty)
                }
            }
            
            
            
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        
        .scrollIndicators(.hidden)
        .onChange(of: query) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                showAnswer = false
                showEmpty  = true
            }
        }
    }
    
    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 6) {
                Text("No Results")
                    .font(.headline)
                Text("Nothing matched \"\(query)\" in your canvases.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
            }
            
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
    }
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "bubbles.and.sparkles")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.top, 2)
                Text("Ask about your canvases")
                
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)

        
    }
    
    private var askAnswerCard: some View {
        HStack(alignment: .top, spacing: 8) {
            
            
            if processor.searchAnswer.isEmpty && processor.isGeneratingSearchAnswer {
                BlinkingCursor()
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(processor.searchAnswer)
                        .font(.body)
                        .animation(.easeInOut, value: processor.searchAnswer)
                    if processor.isGeneratingSearchAnswer {
                        BlinkingCursor()
                            .transition(.opacity)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
}

// MARK: - Canvas List

private struct CanvasListView: View {
    @Environment(\.modelContext) private var context
    
    let canvases: [Canvas]
    
    var body: some View {
        List {
            ForEach(canvases) { canvas in
                NavigationLink(value: canvas) {
                    CanvasCard(canvas: canvas)
                }
                .foregroundStyle(Color(.label))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            .onDelete { offsets in
                for index in offsets {
                    context.delete(canvases[index])
                }
                try? context.save()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Summary (Home)

private struct SummaryView: View {
    @Environment(CanvasProcessor.self) var processor
    
    let allCanvases: [Canvas]
    let clouds: [Cloud]
    let ungroupedClouds: [Cloud]
    let cloudGroups: [CloudGroup]
    
    var body: some View {
        ScrollView {
            GreetingBanner(
                greeting: processor.greeting,
                isGenerating: processor.isGeneratingGreeting
            )
            
            VStack(alignment: .leading, spacing: 28) {
                if !allCanvases.isEmpty {
                    RecentCanvasesSection(canvases: Array(allCanvases.prefix(4)))
                }
                
                ForEach(cloudGroups) { group in
                    CloudGroupSection(group: group)
                }
                
                if !ungroupedClouds.isEmpty {
                    UngroupedCloudsSection(clouds: ungroupedClouds)
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

// MARK: - Recent Canvases Section

private struct RecentCanvasesSection: View {
    let canvases: [Canvas]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Jump Back In")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100)), GridItem(.flexible())],
                alignment: .center,
                spacing: 10
            ) {
                ForEach(canvases) { canvas in
                    NavigationLink(value: canvas) {
                        RecentCanvasCard(canvas: canvas)
                    }
                    .buttonStyle(.automatic)
                    .foregroundStyle(Color(.label))
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Cloud Group Section

private struct CloudGroupSection: View {
    let group: CloudGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Group {
                    if let name = group.name {
                        Text(name).transition(.opacity)
                    } else if !group.sharedTags.isEmpty {
                        Text(group.sharedTags.prefix(3).joined(separator: " · ")).transition(.opacity)
                    } else {
                        BlinkingCursor().transition(.opacity)
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

// MARK: - Ungrouped Clouds Section

private struct UngroupedCloudsSection: View {
    let clouds: [Cloud]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clouds For You")
                .font(.headline)
                .padding(.horizontal)
            
            WidgetGrid(clouds: clouds)
                .padding(.horizontal)
        }
    }
}

// MARK: - Greeting Banner

private struct GreetingBanner: View {
    let greeting: String
    let isGenerating: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(greeting)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.4), value: greeting)
            
            if isGenerating {
                BlinkingCursor().transition(.opacity)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .sensoryFeedback(.success, trigger: isGenerating) { old, new in old && !new }
    }
}

// MARK: - Widget Grid

private struct WidgetGrid: View {
    let clouds: [Cloud]
    
    var body: some View {
        let rows = buildRows(clouds)
        VStack(spacing: 10) {
            ForEach(rows.indices, id: \.self) { i in
                let row = rows[i]
                if row.count == 1 {
                    NavigationLink(value: row[0]) {
                        CloudCard(cloud: row[0])
                    }
                    .buttonStyle(.automatic)
                    .foregroundStyle(Color(.label))
                } else {
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
                if let p = pending { rows.append([p]); pending = nil }
                rows.append([cloud])
            } else {
                if let p = pending { rows.append([p, cloud]); pending = nil }
                else { pending = cloud }
            }
        }
        if let p = pending { rows.append([p]) }
        return rows
    }
}

// MARK: - Preview

#Preview(traits: .mockData) {
    CloudsView()
        .environment(CanvasProcessor())
}

