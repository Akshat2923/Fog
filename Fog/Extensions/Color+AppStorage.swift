//
//  Color+AppStorage.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/25/26.
//

import SwiftUI

extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue),
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(
                  ofClass: UIColor.self, from: data
              ) else { return nil }
        self = Color(uiColor)
    }

    public var rawValue: String {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: UIColor(self),
            requiringSecureCoding: false
        ) else { return "" }
        return data.base64EncodedString()
    }
}
