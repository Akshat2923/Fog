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
            .contentMargins(.horizontal, 10, for: .scrollContent)
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
            .onChange(of: canvas.text) { oldValue, newValue in
                canvas.updatedOn = .now
                
                // Auto-continue: if user pressed Enter on a bullet line, start next bullet
                let newStr = String(newValue.characters)
                let oldStr = String(oldValue.characters)
                
                guard newStr.count > oldStr.count,      // text grew
                      newStr.hasSuffix("\n") else { return }  // last char is newline
                
                // Check if the line that just ended was a bullet line
                let linesBefore = String(newStr.dropLast()).components(separatedBy: "\n")
                guard let lastLine = linesBefore.last,
                      lastLine.hasPrefix("• ") else { return }
                
                // Empty bullet line (user pressed Enter on "• " with no content) — remove it
                if lastLine == "• " {
                    canvas.text = AttributedString(newStr.dropLast().dropLast(2))  // strip "• \n"
                    return
                }
                
                // Continue the list
                canvas.text += AttributedString("• ")
            }
            .onDisappear {
                // If it's a new canvas and still empty, delete it
                if isNew && canvas.text.characters.isEmpty {
                    context.delete(canvas)
                    try? context.save()
                }
            }
            .onAppear {
                if isNew {
                    isFocused = true
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
