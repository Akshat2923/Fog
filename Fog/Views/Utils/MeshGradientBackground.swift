//
//  MeshGradientBackground.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/4/26.
//

import SwiftUI

struct MeshGradientBackground: View {
    @AppStorage("meshOpacityScale") private var meshOpacityScale: Double = 1.0

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color.accentColor.opacity(min(1.0, 0.2 * meshOpacityScale)), Color.accentColor.opacity(min(1.0, 0.3 * meshOpacityScale)), Color.accentColor.opacity(min(1.0, 0.2 * meshOpacityScale)),
                Color.accentColor.opacity(min(1.0, 0.1 * meshOpacityScale)), Color.accentColor.opacity(min(1.0, 0.1 * meshOpacityScale)), Color.accentColor.opacity(min(1.0, 0.1 * meshOpacityScale)),
                Color.accentColor.opacity(min(1.0, 0.2 * meshOpacityScale)), Color.accentColor.opacity(min(1.0, 0.3 * meshOpacityScale)), Color.accentColor.opacity(min(1.0, 0.2 * meshOpacityScale))
            ]
        )
        .ignoresSafeArea()
        .blur(radius: 50)
        .animation(.easeInOut(duration: 0.2), value: meshOpacityScale)
    }
}

#Preview {
    MeshGradientBackground()
}
