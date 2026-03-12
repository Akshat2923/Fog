//
//  SettingsView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/23/26.
//

import SwiftUI
import SwiftData

// MARK: - Pile Row (inline rename)

private struct PileRow: View {
    @Bindable var pile: Pile
    let isActive: Bool
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editedName = ""

    var body: some View {
        HStack(spacing: 12) {
            // Pile color swatch
            Circle()
                .fill(pile.accentColor)
                .frame(width: 12, height: 12)

            if isEditing {
                TextField("Pile name", text: $editedName)
                    .onSubmit { commitRename() }
            } else {
                Text(pile.name)
                if pile.isDefault {
                    Text("Default")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15), in: Capsule())
                }
                if isActive {
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .font(.caption)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !pile.isDefault {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            Button {
                editedName = pile.name
                isEditing = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.orange)
        }
    }

    private func commitRename() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { pile.name = trimmed }
        isEditing = false
    }
}

// MARK: - Pile Theme Editor

private struct PileThemeEditor: View {
    @Bindable var pile: Pile
    @Environment(PileManager.self) private var pileManager

    var body: some View {
        Section(header: Text("Theme — \(pile.name)")) {
            ColorPicker("Accent Color", selection: Binding(
                get: { pile.accentColor },
                set: { pile.accentColor = $0; pileManager.syncAppStorage() }
            ), supportsOpacity: false)

            Toggle("Apply as Tint Color?", isOn: Binding(
                get: { pile.useFullTint },
                set: { pile.useFullTint = $0; pileManager.syncAppStorage() }
            ))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Background Intensity")
                        .foregroundStyle(pile.rainbowRave ? .secondary : .primary)
                    Spacer()
                    Text(String(format: "%.0f%%", pile.meshOpacityScale * 100))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .accessibilityHidden(true)
                }
                Slider(value: Binding(
                    get: { pile.meshOpacityScale },
                    set: { pile.meshOpacityScale = $0; pileManager.syncAppStorage() }
                ), in: 0...2, step: 0.05) {
                    Text("Background Gradient Intensity")
                } minimumValueLabel: {
                    Image(systemName: "sun.min")
                } maximumValueLabel: {
                    Image(systemName: "sun.max")
                }
                .disabled(pile.rainbowRave)
                .accessibilityLabel("Background intensity")
            }

            Toggle("Rainbow Rave", isOn: Binding(
                get: { pile.rainbowRave },
                set: { pile.rainbowRave = $0; pileManager.syncAppStorage() }
            ))
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(PileManager.self) private var pileManager

    @Query(sort: \Pile.createdOn, order: .forward) private var allPiles: [Pile]

    @State private var showDeleteConfirm = false
    @State private var showAddPile = false
    @State private var newPileName = ""
    @State private var pileToDelete: Pile?

    var body: some View {
        NavigationStack {
            List {
                // MARK: Piles
                Section(header: Text("Piles")) {
                    ForEach(allPiles) { pile in
                        PileRow(
                            pile: pile,
                            isActive: pile === pileManager.activePile,
                            onDelete: {
                                pileToDelete = pile
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            pileManager.switchTo(pile)
                        }
                    }

                    Button {
                        newPileName = ""
                        showAddPile = true
                    } label: {
                        Label("New Pile", systemImage: "plus")
                    }
                }

                // MARK: Active Pile Theme
                if let activePile = pileManager.activePile {
                    PileThemeEditor(pile: activePile)
                }

                // MARK: Data
                Section(
                    header: Text("Data"),
                    footer: Text("Permanently deletes all canvases, clouds, and piles.")
                ) {
                    Button("Delete All Data", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            // Add pile alert
            .alert("New Pile", isPresented: $showAddPile) {
                TextField("Name", text: $newPileName)
                Button("Create") {
                    let trimmed = newPileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    pileManager.createPile(named: trimmed, context: context, switchToNew: true)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Give your new pile a name.")
            }
            // Delete pile confirm
            .alert("Delete Pile?", isPresented: Binding(
                get: { pileToDelete != nil },
                set: { if !$0 { pileToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let pile = pileToDelete {
                        pileManager.deletePile(pile, from: allPiles, context: context)
                        pileToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) { pileToDelete = nil }
            } message: {
                Text("This will permanently delete this pile and all its canvases and clouds.")
            }
            // Delete all data confirm
            .alert("Delete All Data?", isPresented: $showDeleteConfirm) {
                Button("Delete Everything", role: .destructive) {
                    try? context.delete(model: Canvas.self)
                    try? context.delete(model: Cloud.self)
                    try? context.delete(model: Pile.self)
                    dismiss()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}
