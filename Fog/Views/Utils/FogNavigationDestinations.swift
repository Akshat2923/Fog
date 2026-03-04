//
//  FogNavigationDestinations.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/23/26.
//


import SwiftUI
import SwiftData

struct FogNavigationDestinations: ViewModifier {
    let namespace: Namespace.ID
    @Binding var path: NavigationPath

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Cloud.self) { cloud in
                CloudDetailView(cloud: cloud, namespace: namespace)
                    .toolbarRole(.editor)
            }
            .navigationDestination(for: Canvas.self) { canvas in
                
//                CanvasEditorView(canvas: canvas, path: $path)
//                    .toolbarRole(.editor)
//                    .navigationTransition(.zoom(
//                        sourceID: canvas.isNew == true ? AnyHashable("createCanvas") : AnyHashable(canvas.id),
//                        in: namespace
//                    ))
                
                if canvas.isNew == true {
                    CanvasEditorView(canvas: canvas, path: $path)
                        .toolbarRole(.editor)
                        .navigationTransition(.zoom(sourceID: "createCanvas", in: namespace))
                } else {
                    CanvasEditorView(canvas: canvas, path: $path)
                        .toolbarRole(.editor)
                }
            }
    }
}

