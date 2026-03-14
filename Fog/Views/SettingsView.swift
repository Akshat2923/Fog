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
    @AppStorage("meshOpacityScale") private var meshOpacityScale: Double = 1.0
    @AppStorage("rainbowRave") private var rainbowRave: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    ColorPicker("Accent Color", selection: $accentColor)
                    Toggle("Apply as Tint Color?", isOn: $useFullTint)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Background Intensity")
                                .foregroundStyle(rainbowRave ? .secondary : .primary)
                            Spacer()
                            Text(String(format: "%.0f%%", meshOpacityScale * 100))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .accessibilityHidden(true)
                        }
                        Slider(value: $meshOpacityScale, in: 0...2, step: 0.05) {
                            Text("Background Gradient Intensity")
                        } minimumValueLabel: {
                            Image(systemName: "sun.min")
                        } maximumValueLabel: {
                            Image(systemName: "sun.max")
                        }
                        .disabled(rainbowRave)
                        .accessibilityLabel("Background intensity")
                    }
                    Toggle("Rainbow Rave", isOn: $rainbowRave)
                    
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
            .alert(
                "Delete All Data?",
                isPresented: $showDeleteConfirm,
            ) {
                Button("Delete Everything", role: .destructive) {
                    try? context.delete(model: Cloud.self)
                    try? context.save()
                    try? context.delete(model: Canvas.self)
                    try? context.save()
                    dismiss()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}
