//
//  RichTextToolbar.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/23/26.
//

import SwiftUI

struct RichTextToolbar: ViewModifier {
    @Binding var text: AttributedString
    @Binding var selection: AttributedTextSelection
    var isFocused: FocusState<Bool>.Binding
    @State private var showMoreFormatting = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Group {
                        FormatStyleButtons(text: $text, selection: $selection)
                        Spacer()
                        Button {
                            showMoreFormatting.toggle()
                        } label: {
                            Image(systemName: "textformat.alt")
                        }
                        Button {
                            isFocused.wrappedValue = false
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    }
                    .disabled(!isFocused.wrappedValue)
                }
            }
            .sheet(isPresented: $showMoreFormatting) {
                MoreFormattingView(text: $text, selection: $selection)
                    .presentationDetents([.height(200)])
            }
    }
}

extension View {
    func richTextToolbar(
        text: Binding<AttributedString>,
        selection: Binding<AttributedTextSelection>,
        isFocused: FocusState<Bool>.Binding  
    ) -> some View {
        modifier(RichTextToolbar(text: text, selection: selection, isFocused: isFocused))
    }
}
