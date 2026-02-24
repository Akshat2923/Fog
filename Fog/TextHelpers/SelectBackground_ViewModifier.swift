//
//  SelectBackground_ViewModifier.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import Foundation
import SwiftUI

struct SelectedBackground: ViewModifier {
    let state: Bool
    let isButton: Bool
    func body(content: Content) -> some View {
        if state {
            if isButton {
                content
                    .foregroundStyle(.white)
                    .background(.tint, in: .circle)
            } else {
                content
                    .foregroundStyle(.white)
                    .background(.tint, in: .rect(cornerRadius: 8))
            }
        } else {
            content
        }
    }
}

extension View {
    func selectedBackground(state: Bool, isButton: Bool = true) -> some View {
        modifier(SelectedBackground(state: state, isButton: isButton))
    }
}
