//
//  CanvasEditorView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/23/26.
//

import SwiftUI
import SwiftData

struct CanvasEditorView: View {
    @Bindable var canvas: Canvas
    let isNew: Bool

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(CanvasProcessor.self) var processor

    @State private var selection = AttributedTextSelection()
    @FocusState private var isFocused: Bool
    @State private var showDeleteConfirm = false

    var body: some View {
        TextEditor(text: $canvas.text, selection: $selection)
            .focused($isFocused)
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(isNew ? "New Canvas" : (canvas.title ?? "Canvas"))
            .toolbarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isNew)
            .richTextToolbar(text: $canvas.text, selection: $selection, isFocused: $isFocused)
            .toolbar {
                if !isNew {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu("Actions", systemImage: "trash") {
                            Button("Delete Canvas? ", systemImage: "trash", role: .destructive) {
                                context.delete(canvas)
                                dismiss()
                            }
                        }
                        .menuIndicator(.hidden)
                    }
                }
                // Custom back only needed for new canvases
                if isNew {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if canvas.text.characters.isEmpty {
                                context.delete(canvas)
                                try? context.save()
                                dismiss()
                            } else {
                                confirmAndDismiss()
                            }
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            confirmAndDismiss()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .disabled(canvas.text.characters.isEmpty)
                    }
                }
            }
            .onChange(of: canvas.text) {
                canvas.updatedOn = .now
            }
            .onDisappear {
                // If it's a new canvas and still empty, delete it
                if isNew && canvas.text.characters.isEmpty {
                    context.delete(canvas)
                    try? context.save()
                }
            }
            
    }

    private func confirmAndDismiss() {
        dismiss()
        if !processor.isModelAvailable { return }
        Task {
            await processor.processCanvas(canvas, context: context)
        }
    }
}

#Preview(traits: .mockData) {
    @Previewable @Query var canvases: [Canvas]
    NavigationStack {
        if let first = canvases.first {
            CanvasEditorView(canvas: first, isNew: false)
                .environment(CanvasProcessor())
        }
    }
}
