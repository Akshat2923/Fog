//
//  CloudCard.swift
//  Fog
//

import SwiftUI

// MARK: - Widget Size

enum CloudWidgetSize {
    case small   // 1-4 canvases:  1×1 square, half-width
    case medium  // 5-9 canvases:  2×1 wide, full-width
    case large   // 10+ canvases:  2×2 tall, full-width

    init(canvasCount: Int) {
        switch canvasCount {
        case 0...4:  self = .small
        case 5...9:  self = .medium
        default:     self = .large
        }
    }

    var height: CGFloat {
        switch self {
        case .small:  return 155
        case .medium: return 155
        case .large:  return 300
        }
    }

    var isWide: Bool {
        self == .medium || self == .large
    }
}

// MARK: - Card

struct CloudCard: View {
    let cloud: Cloud

    private var widgetSize: CloudWidgetSize {
        CloudWidgetSize(canvasCount: cloud.canvases.count)
    }

    private var tintOpacity: Double {
        switch widgetSize {
        case .small:  return 0.1
        case .medium: return 0.25
        case .large:  return 0.50
        }
    }

    private var titleFont: Font {
        switch widgetSize {
        case .small:  return .headline
        case .medium: return .title2
        case .large:  return .largeTitle
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(cloud.canvases.count) canvas\(cloud.canvases.count == 1 ? "" : "es")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(cloud.name.isEmpty ? "New Cloud" : cloud.name)
                .multilineTextAlignment(.leading)
                .font(titleFont)
                .lineLimit(widgetSize == .large ? 4 : 2)
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
        .frame(height: widgetSize.height)
        .glassEffect(
            .regular.tint(.accentColor.opacity(tintOpacity)).interactive(),
            in: .rect(cornerRadius: 34)
        )
    }
}
