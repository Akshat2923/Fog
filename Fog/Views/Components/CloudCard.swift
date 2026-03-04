//
//  CloudCard.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/1/26.
//

import SwiftUI

struct CloudCard: View {
    let cloud: Cloud
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(cloud.canvases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(cloud.name.isEmpty ? "New Cloud" : cloud.name)
                .font(.headline)
                .lineLimit(2)
                .redacted(reason: cloud.name.isEmpty ? .placeholder : [])
                .animation(.easeInOut, value: cloud.name)
            if !cloud.cloudTags.isEmpty {
                Text(cloud.cloudTags.prefix(3).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 130)
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
