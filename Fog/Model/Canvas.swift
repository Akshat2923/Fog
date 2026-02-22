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
    var createdOn: Date
    var updatedOn: Date
    var cloud: Cloud?
    
    init(text: AttributedString = "") {
        self.text = text
        self.title = nil
        self.tags = []
        self.createdOn = .now
        self.updatedOn = .now
    }
}
