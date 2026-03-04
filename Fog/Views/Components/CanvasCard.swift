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
    
    private var cloudName: String? {
        canvas.cloud?.name.isEmpty == false ? canvas.cloud?.name : nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showTitle {
                Text(canvas.title ?? "Processing...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .redacted(reason: canvas.title == nil ? .placeholder : [])
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
                    Label(name, systemImage: "cloud.fill")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .glassEffect(
            .regular.tint(
                .accentColor.opacity(
                    0.025
                )
            ).interactive(),
            in: .rect(
                cornerRadius: 34
            )
        )
    }
}
