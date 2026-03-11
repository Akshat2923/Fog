// GraphView.swift
// Fog

import SwiftUI
import SwiftData

// MARK: Need to revisit as it lacks polish, v2

private enum NodeKind {
    case canvas, cloud, cloudGroup
}

private struct GraphNode: Identifiable {
    let id: String
    let kind: NodeKind
    let label: String
    let tags: [String]
    let detailText: String?
    let countLabel: String?
    let groupDescription: String?
    var position: CGPoint
    var velocity: CGPoint = .zero

    var radius: CGFloat {
        switch kind {
        case .canvas:     return 7
        case .cloud:      return 13
        case .cloudGroup: return 19
        }
    }

    var tint: Color {
        switch kind {
        case .canvas:     return .accentColor
        case .cloud:      return .orange
        case .cloudGroup: return .purple
        }
    }
}

private struct GraphEdge: Identifiable {
    let id: String
    let from: String
    let to: String
    let weight: CGFloat
}

// MARK: - Simulation

@Observable
@MainActor
private final class GraphSimulation {
    var nodes: [GraphNode] = []
    var edges: [GraphEdge] = []
    private var displayLink: Timer?

    func build(canvases: [Canvas], clouds: [Cloud], cloudGroups: [CloudGroup], in size: CGSize) {
        displayLink?.invalidate()
        var newNodes: [GraphNode] = []
        var newEdges: [GraphEdge] = []
        let cx = size.width / 2, cy = size.height / 2

        var cloudToGroupIdx: [String: Int] = [:]
        for (i, g) in cloudGroups.enumerated() {
            for c in g.clouds { cloudToGroupIdx[c.name] = i }
        }

        for (i, group) in cloudGroups.enumerated() {
            let total = group.clouds.reduce(0) { $0 + $1.canvases.count }
            let angle = Double(i) / Double(max(cloudGroups.count, 1)) * 2 * .pi
            newNodes.append(GraphNode(
                id: "cg-\(i)", kind: .cloudGroup,
                label: group.name ?? group.sharedTags.prefix(2).joined(separator: " · "),
                tags: group.sharedTags,
                detailText: nil,
                countLabel: "\(group.clouds.count) cloud\(group.clouds.count == 1 ? "" : "s")",
                groupDescription: group.groupDescription,
                position: CGPoint(x: cx + 70 * cos(angle), y: cy + 70 * sin(angle))
            ))
            _ = total
        }

        for (i, cloud) in clouds.enumerated() {
            let angle = Double(i) / Double(max(clouds.count, 1)) * 2 * .pi
            let r: Double = cloudGroups.isEmpty ? 110 : 150
            let cloudId = "cl-\(i)"
            newNodes.append(GraphNode(
                id: cloudId, kind: .cloud,
                label: cloud.name.isEmpty ? "Unnamed Cloud" : cloud.name,
                tags: cloud.cloudTags,
                detailText: nil,
                countLabel: "\(cloud.canvases.count) canvas\(cloud.canvases.count == 1 ? "" : "es")",
                groupDescription: nil,
                position: CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            ))
            if let gIdx = cloudToGroupIdx[cloud.name] {
                newEdges.append(GraphEdge(id: "e-cg\(gIdx)-\(cloudId)", from: "cg-\(gIdx)", to: cloudId, weight: 2))
            }
        }

        for (i, canvas) in canvases.enumerated() {
            let angle = Double(i) / Double(max(canvases.count, 1)) * 2 * .pi
            let r: Double = 200
            let canvasId = "cv-\(i)"
            newNodes.append(GraphNode(
                id: canvasId, kind: .canvas,
                label: canvas.title ?? String(canvas.text.characters.prefix(22)),
                tags: canvas.tags,
                detailText: String(canvas.text.characters.prefix(160)),
                countLabel: nil,
                groupDescription: nil,
                position: CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            ))
            if let cloud = canvas.cloud,
               let ci = clouds.firstIndex(where: { $0.name == cloud.name }) {
                newEdges.append(GraphEdge(id: "e-cl\(ci)-\(canvasId)", from: "cl-\(ci)", to: canvasId, weight: 1))
            }
        }

        nodes = newNodes
        edges = newEdges
        startSimulation(in: size)
    }

    func startSimulation(in size: CGSize) {
        var iter = 0
        displayLink = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            iter += 1
            let cooling = max(0.25, 1.0 - Double(iter) / 280.0)
            DispatchQueue.main.async { self.tick(size: size, cooling: cooling) }
            if iter > 350 { t.invalidate() }
        }
    }

    func stop() { displayLink?.invalidate() }

    private func tick(size: CGSize, cooling: Double) {
        let repulsion: CGFloat = 2800
        let springLen: CGFloat = 85
        let springK: CGFloat   = 0.055
        let damping: CGFloat   = 0.78
        let gravity: CGFloat   = 0.003

        var fx = [String: CGFloat]()
        var fy = [String: CGFloat]()
        for n in nodes { fx[n.id] = 0; fy[n.id] = 0 }

        for i in nodes.indices {
            for j in nodes.indices where j != i {
                let dx = nodes[i].position.x - nodes[j].position.x
                let dy = nodes[i].position.y - nodes[j].position.y
                let d2 = max(1, dx*dx + dy*dy)
                let d  = sqrt(d2)
                let f  = repulsion / d2
                fx[nodes[i].id]! += f * dx / d
                fy[nodes[i].id]! += f * dy / d
            }
        }

        let idxMap = Dictionary(uniqueKeysWithValues: nodes.enumerated().map { ($0.element.id, $0.offset) })
        for e in edges {
            guard let fi = idxMap[e.from], let ti = idxMap[e.to] else { continue }
            let dx = nodes[ti].position.x - nodes[fi].position.x
            let dy = nodes[ti].position.y - nodes[fi].position.y
            let d  = max(1, sqrt(dx*dx + dy*dy))
            let f  = springK * (d - springLen) * e.weight
            fx[nodes[fi].id]! += f * dx / d;  fy[nodes[fi].id]! += f * dy / d
            fx[nodes[ti].id]! -= f * dx / d;  fy[nodes[ti].id]! -= f * dy / d
        }

        let cx = size.width / 2, cy = size.height / 2
        for n in nodes {
            fx[n.id]! += (cx - n.position.x) * gravity
            fy[n.id]! += (cy - n.position.y) * gravity
        }

        for i in nodes.indices {
            nodes[i].velocity.x = (nodes[i].velocity.x + fx[nodes[i].id]!) * damping * CGFloat(cooling)
            nodes[i].velocity.y = (nodes[i].velocity.y + fy[nodes[i].id]!) * damping * CGFloat(cooling)
            nodes[i].position.x = max(nodes[i].radius, min(size.width  - nodes[i].radius, nodes[i].position.x + nodes[i].velocity.x))
            nodes[i].position.y = max(nodes[i].radius, min(size.height - nodes[i].radius, nodes[i].position.y + nodes[i].velocity.y))
        }
    }
}

// MARK: - GraphView

struct GraphView: View {
    let canvases: [Canvas]
    let clouds:   [Cloud]
    let cloudGroups: [CloudGroup]

    @State private var sim = GraphSimulation()
    @State private var selectedId: String?
    @State private var presentedNode: GraphNode?
    @State private var panOffset: CGSize = .zero
    @State private var lastPan:   CGSize = .zero
    @State private var zoom: CGFloat = 1.0
    @GestureState private var liveZoom: CGFloat = 1.0

    private var selectedNode: GraphNode? {
        guard let id = selectedId else { return nil }
        return sim.nodes.first { $0.id == id }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Edge + node canvas
                graphLayer(size: geo.size)
                    .scaleEffect(zoom * liveZoom, anchor: .center)
                    .offset(panOffset)
                    .gesture(panGesture)
                    .gesture(pinchGesture)

                
            }
            .sheet(item: $presentedNode, onDismiss: { selectedId = nil }) { node in
                NodeDetailSheet(node: node)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .toolbar {
                ToolbarItem (placement: .status){
                    legendView
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .onAppear   { sim.build(canvases: canvases, clouds: clouds, cloudGroups: cloudGroups, in: geo.size) }
            .onDisappear{ sim.stop() }
            .onChange(of: canvases.count)    { sim.build(canvases: canvases, clouds: clouds, cloudGroups: cloudGroups, in: geo.size) }
            .onChange(of: clouds.count)      { sim.build(canvases: canvases, clouds: clouds, cloudGroups: cloudGroups, in: geo.size) }
            .onChange(of: cloudGroups.count) { sim.build(canvases: canvases, clouds: clouds, cloudGroups: cloudGroups, in: geo.size) }
        }
    }

    // MARK: Graph layer

    @ViewBuilder
    private func graphLayer(size: CGSize) -> some View {
        let posMap = Dictionary(uniqueKeysWithValues: sim.nodes.map { ($0.id, $0.position) })

        SwiftUI.Canvas { ctx, _ in
            for edge in sim.edges {
                guard let a = posMap[edge.from], let b = posMap[edge.to] else { continue }
                let highlighted = selectedId == nil || edge.from == selectedId || edge.to == selectedId
                var p = Path(); p.move(to: a); p.addLine(to: b)
                ctx.stroke(p, with: .color(.primary.opacity(highlighted ? 0.15 : 0.05)), lineWidth: edge.weight * 0.7)
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            ForEach(sim.nodes) { node in
                nodeView(node)
                    .position(node.position)
            }
        }
    }

    // MARK: Node bubble

    @ViewBuilder
    private func nodeView(_ node: GraphNode) -> some View {
        let isSelected = selectedId == node.id
        let isLit: Bool = {
            guard let sel = selectedId else { return true }
            if node.id == sel { return true }
            return sim.edges.contains { ($0.from == sel && $0.to == node.id) || ($0.to == sel && $0.from == node.id) }
        }()

        ZStack {
            Circle()
                .fill(node.tint.opacity(isSelected ? 0.35 : 0.18))
                .frame(width: node.radius * 2, height: node.radius * 2)
                .glassEffect(
                    .regular.tint(node.tint.opacity(isSelected ? 1.0 : 0.75)).interactive(),
                    in: Circle()
                )
                .scaleEffect(isSelected ? 1.25 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
                .opacity(isLit ? 1 : 0.3)

            if node.kind != .canvas || isSelected {
                Text(node.label)
                    .font(.system(size: max(7, min(11, 10 / zoom)), weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineLimit(1)
                    .fixedSize()
                    .offset(y: -(node.radius + 9))
                    .opacity(isLit ? 1 : 0.2)
            }
        }
        .contentShape(Circle().size(CGSize(width: node.radius * 3.5, height: node.radius * 3.5)))
        .onTapGesture {
            selectedId = node.id
            presentedNode = node
        }
    }

    // MARK: Legend

    private var legendView: some View {
        HStack(alignment: .center, spacing: 16) {
            ForEach([("Canvas", NodeKind.canvas), ("Cloud", .cloud), ("Cloud Group", .cloudGroup)], id: \.0) { name, kind in
                HStack(spacing: 5) {
                    Circle()
                        .fill(tintFor(kind).opacity(0.7))
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Gestures

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                panOffset = CGSize(
                    width:  lastPan.width  + v.translation.width,
                    height: lastPan.height + v.translation.height
                )
            }
            .onEnded { v in
                lastPan = panOffset
            }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .updating($liveZoom) { val, state, _ in state = val }
            .onEnded { val in zoom = max(0.3, min(4, zoom * val)) }
    }

    // MARK: Helpers

    private func kindName(_ k: NodeKind) -> String {
        switch k { case .canvas: "Canvas"; case .cloud: "Cloud"; case .cloudGroup: "Cloud Group" }
    }
    private func kindIcon(_ k: NodeKind) -> String {
        switch k { case .canvas: "doc.text"; case .cloud: "cloud.fill"; case .cloudGroup: "square.3.layers.3d" }
    }
    private func tintFor(_ k: NodeKind) -> Color {
        switch k { case .canvas: .accentColor; case .cloud: .orange; case .cloudGroup: .purple }
    }
}

// MARK: - Node detail sheet

private struct NodeDetailSheet: View {
    let node: GraphNode

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(kindName(node.kind), systemImage: kindIcon(node.kind))
                        .foregroundStyle(node.tint)
                }

                if !node.tags.isEmpty {
                    Section("Tags") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(node.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .glassEffect(.regular.tint(.accentColor.opacity(0.3)), in: Capsule())
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if let detail = node.detailText, !detail.isEmpty {
                    Section("Preview") {
                        Text(detail)
                            .foregroundStyle(.secondary)
                    }
                }

                if let count = node.countLabel {
                    Section {
                        Text(count)
                            .foregroundStyle(.secondary)
                    }
                }

                if let desc = node.groupDescription {
                    Section("About") {
                        Text(desc)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(node.label)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func kindName(_ k: NodeKind) -> String {
        switch k { case .canvas: "Canvas"; case .cloud: "Cloud"; case .cloudGroup: "Cloud Group" }
    }
    private func kindIcon(_ k: NodeKind) -> String {
        switch k { case .canvas: "doc.text"; case .cloud: "cloud.fill"; case .cloudGroup: "square.3.layers.3d" }
    }
}

