//
//  RecentCanvasCard.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/1/26.
//

import SwiftUI

struct RecentCanvasCard: View {
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
            
            HStack {
                Text(canvas.updatedOn.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.footnote)
                    .lineLimit(1)

                
                Spacer()
                
                if let name = cloudName {
                    Label(name, systemImage: "cloud.fill")
                        .font(.footnote)
                        .italic()
                        .lineLimit(1)
                }
            }
        }
        .padding()
//        .glassEffect(.regular.tint(.accentColor.opacity(0.1)).interactive())
        .glassEffect(
            .regular.tint(
                .accentColor.opacity(
                    0.3
                )
            ).interactive(),
            in: .rect(
                cornerRadius: 34
            )
        )
    }
}

