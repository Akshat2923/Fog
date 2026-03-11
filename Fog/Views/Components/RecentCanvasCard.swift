//
//  RecentCanvasCard.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/1/26.
//

import SwiftUI

struct RecentCanvasCard: View {
    let canvas: Canvas
    
    private var cloudName: String? {
        canvas.cloud?.name.isEmpty == false ? canvas.cloud?.name : nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let title = canvas.title {
                    Text(title)
                        .transition(.opacity)
                } else {
                    BlinkingCursor()
                        .transition(.opacity)
                }
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .lineLimit(1)
            .animation(.easeInOut, value: canvas.title)
            
            
            HStack {
                Text(canvas.updatedOn.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.footnote)
                    .lineLimit(1)
                
                
                Spacer()
                
                if let name = cloudName {
                    Label(name, systemImage: "cloud")
                        .font(.footnote)
                        .italic()
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .glassEffect(.regular.interactive(), in: .capsule)
        
    }
}

