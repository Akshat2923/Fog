//
//  FogToolBar.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/25/26.
//

import SwiftUI
import SwiftData

struct FogToolbar: ViewModifier {
    @Environment(\.modelContext) private var context

    let namespace: Namespace.ID
    @Binding var path: NavigationPath

    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .matchedTransitionSource(id: "settings", in: namespace)
                }
                ToolbarItem(placement: .confirmationAction) {
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .navigationTransition(.zoom(sourceID: "settings", in: namespace))
                    .presentationDetents([.medium, .large])
            }
    }
}

extension View {
    func fogToolBar(namespace: Namespace.ID, path: Binding<NavigationPath>) -> some View {
        modifier(FogToolbar(namespace: namespace, path: path))
    }
}

