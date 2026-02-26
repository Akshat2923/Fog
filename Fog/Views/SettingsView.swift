//
//  SettingsView.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/23/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false
    @AppStorage("accentColor") private var accentColor: Color = .primary
    @AppStorage("useFullTint") private var useFullTint: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    ColorPicker("Accent Color", selection: $accentColor)
                    Toggle("Apply as full app tint?", isOn: $useFullTint)
                }
                
                Section(header: Text("Data"), footer: Text("This permanently deletes all canvases and clouds.")) {
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
            .confirmationDialog(
                "Delete All Data?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    try? context.delete(model: Canvas.self)
                    try? context.delete(model: Cloud.self)
                    dismiss()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}

