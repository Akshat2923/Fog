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
    @Binding var path: NavigationPath
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(CanvasProcessor.self) private var processor
    
    @State private var selection = AttributedTextSelection()
    @FocusState private var isFocused: Bool
    @State private var hasEdited = false
    @State private var wasNew = false
    @State private var didManuallyProcess = false
    
    private var isNew: Bool { canvas.isNew == true }
    
    var body: some View {
        TextEditor(text: $canvas.text, selection: $selection)
            .toolbar(.hidden, for: .tabBar)
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
                            Button("Delete Canvas?", systemImage: "trash", role: .destructive) {
                                context.delete(canvas)
                                
                                dismiss()
                            }
                        }
                        .menuIndicator(.hidden)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            saveAndStartNew()
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .buttonStyle(.glassProminent)
                        
                    }
                }
                if isNew {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            handleDisappear()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            canvas.isNew = false
                            isFocused = false
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(canvas.text.characters.isEmpty)
                    }
                }
            }
            .onChange(of: canvas.text) { oldValue, newValue in
                hasEdited = true
                
                guard newValue.characters.last == "\n",
                      oldValue.characters.last != "\n" else { return }
                
                let chars = newValue.characters
                let contentBeforeNewline = chars.dropLast()
                guard let lastNewline = contentBeforeNewline.lastIndex(of: "\n") else {
                    let lastLine = String(contentBeforeNewline)
                    if lastLine.hasPrefix("• ") {
                        if lastLine == "• " {
                            canvas.text = AttributedString(String(chars.dropLast().dropLast(2)))
                        } else {
                            canvas.text += AttributedString("• ")
                        }
                    }
                    return
                }
                
                let lastLine = String(contentBeforeNewline[contentBeforeNewline.index(after: lastNewline)...])
                guard lastLine.hasPrefix("• ") else { return }
                
                if lastLine == "• " {
                    canvas.text = AttributedString(String(chars.dropLast().dropLast(2)))
                } else {
                    canvas.text += AttributedString("• ")
                }
            }
            .onDisappear {
                handleDisappear()
            }
            .onAppear {
                wasNew = isNew
                if isNew { isFocused = true }
            }
    }
    
    private func saveAndStartNew() {
        didManuallyProcess = true
        canvas.isNew = false
        canvas.updatedOn = .now
        if processor.isModelAvailable {
            Task { await processor.processCanvas(canvas, context: context) }
        }
        let next = Canvas()
        context.insert(next)
        path.append(next)
    }
    
    private func handleDisappear() {
        guard !didManuallyProcess else { return }
        if wasNew && canvas.text.characters.isEmpty {
            context.delete(canvas)
            try? context.save()
        } else if wasNew {
            // left without confirming — process on the way out
            canvas.isNew = false
            canvas.updatedOn = .now
            guard processor.isModelAvailable else { return }
            Task { await processor.processCanvas(canvas, context: context) }
        } else if hasEdited {
            canvas.updatedOn = .now
        }
    }
}

#Preview(traits: .mockData) {
    @Previewable @Query var canvases: [Canvas]
    @Previewable @State var path = NavigationPath()
    NavigationStack(path: $path) {
        if let first = canvases.first {
            CanvasEditorView(canvas: first, path: $path)
                .environment(CanvasProcessor())
        }
    }
}
