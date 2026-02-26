//
//  FogNavigationDestinations.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/23/26.
//

import SwiftUI
import SwiftData

struct FogNavigationDestinations: ViewModifier {
    @Environment(\.modelContext) private var context
    @Environment(CanvasProcessor.self) private var processor
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Cloud.self) { cloud in
                CloudDetailView(cloud: cloud, namespace: namespace)
                    // .editor hides the back button label, shows just the chevron
                    .toolbarRole(.editor)
                    .navigationTransition(.zoom(sourceID: cloud.id, in: namespace))
            }
            .navigationDestination(for: Canvas.self) { canvas in
                let isNew = canvas.title == nil
                if isNew {
                    CanvasEditorView(canvas: canvas, isNew: true)
                        .toolbarRole(.editor)
                        .navigationTransition(.zoom(sourceID: "createCanvas", in: namespace))
                } else {
                    CanvasEditorView(canvas: canvas, isNew: false)
                        .toolbarRole(.editor)
                        .navigationTransition(.zoom(sourceID: canvas.id, in: namespace))
                }
            }
    }
}
