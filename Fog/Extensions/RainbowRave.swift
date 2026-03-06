//
//  RainbowRave.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/5/26.
//

import Foundation
import SwiftUI

extension Color {
    struct RainbowRave {
        static let mandy = Color(hex: 0xED5A77)
        static let ecstasy = Color(hex: 0xFB861E)
        static let silverSand = Color(hex: 0xC5C8CC)
        static let mediumPurple = Color(hex: 0x967BE3)
        static let cornflowerBlue = Color(hex: 0x4999F5)
        static let tonysPink = Color(hex: 0xE79B8B)
        static let redRibbon = Color(hex: 0xFB105A)
        static let fuchsiaPink = Color(hex: 0xBF6FB6)
        static let wisteria = Color(hex: 0xA176C2)
        static let danube = Color(hex: 0x6494C4)
    }
    
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
