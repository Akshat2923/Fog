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
                ToolbarItem(placement: .topBarTrailing) {
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
                if #available(iOS 18.0, macOS 15.0, *) {
                    SettingsView()
                        .navigationTransition(.zoom(sourceID: "settings", in: namespace))
                } else {
                    SettingsView()
                }
            }
    }
}

extension View {
    func fogToolBar(namespace: Namespace.ID, path: Binding<NavigationPath>) -> some View {
        modifier(FogToolbar(namespace: namespace, path: path))
    }
}
