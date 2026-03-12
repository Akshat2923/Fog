//
//  Pile.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/11/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Pile {
    var name: String
    var isDefault: Bool
    var createdOn: Date

    // Per-pile theme — stored as base64-encoded NSKeyedArchiver Data (same as Color+AppStorage)
    var accentColorRaw: String
    var useFullTint: Bool
    var meshOpacityScale: Double
    var rainbowRave: Bool

    @Relationship(deleteRule: .cascade, inverse: \Canvas.pile)
    var canvases: [Canvas]

    @Relationship(deleteRule: .cascade, inverse: \Cloud.pile)
    var clouds: [Cloud]

    init(name: String, isDefault: Bool = false) {
        self.name = name
        self.isDefault = isDefault
        self.createdOn = .now
        self.accentColorRaw = Color.primary.rawValue
        self.useFullTint = false
        self.meshOpacityScale = 1.0
        self.rainbowRave = false
        self.canvases = []
        self.clouds = []
    }

    var accentColor: Color {
        get { Color(rawValue: accentColorRaw) ?? .primary }
        set { accentColorRaw = newValue.rawValue }
    }
}
