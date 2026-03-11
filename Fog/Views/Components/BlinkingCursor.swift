//
//  BlinkingCursor.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/10/26.
//

import SwiftUI

struct BlinkingCursor: View {
    @State private var visible = false
    
    var body: some View {
        Text("|")
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    visible = true
                }
            }
    }
}

#Preview {
    BlinkingCursor()
        .font(.subheadline)
        .fontWeight(.semibold)
}
