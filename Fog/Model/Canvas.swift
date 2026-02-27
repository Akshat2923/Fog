//
//  Canvas.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import Foundation
import SwiftData

@Model
class Canvas {
    var text: AttributedString
    var title: String?
    var tags: [String]
    var isNew: Bool?
    var createdOn: Date
    var updatedOn: Date
    var cloud: Cloud?

    init(text: AttributedString = "") {
        self.text = text
        self.title = nil
        self.tags = []
        self.isNew = true
        self.createdOn = .now
        self.updatedOn = .now
    }
}
