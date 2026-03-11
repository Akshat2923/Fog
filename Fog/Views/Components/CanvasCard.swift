//
//  CanvasCard.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/1/26.
//

import SwiftUI

struct CanvasCard: View {
    let canvas: Canvas
    var showTitle: Bool = true
    @Environment(CanvasProcessor.self) private var processor
    private var cloudName: String? {
        canvas.cloud?.name.isEmpty == false ? canvas.cloud?.name : nil
    }
    
    private var displayTitle: String {
        if processor.isModelAvailable {
            return canvas.title ?? "Processing..."
        } else {
            let chars = String(canvas.text.characters.prefix(15))
            return chars.isEmpty ? "New Canvas" : chars
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showTitle {
                Group {
                    if let title = canvas.title {
                        Text(title)
                            .transition(.opacity)
                    } else if processor.isModelAvailable && canvas.title == nil {
                        BlinkingCursor()
                            .transition(.opacity)
                    } else {
                        Text(displayTitle)
                            .transition(.opacity)
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundStyle(canvas.title == nil ? .secondary : .primary)
                .animation(.easeInOut, value: canvas.title)
            }
            
            Text(String(canvas.text.characters.prefix(200)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            HStack {
                Text(canvas.createdOn, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                if let name = cloudName {
                    Label(name, systemImage: "cloud")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        
        
    }
}
