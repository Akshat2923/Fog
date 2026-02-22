//
//  Cloud.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import Foundation
import SwiftData

@Model
class Cloud {
    var name: String
    var cloudTags: [String]
    var createdOn: Date

    @Relationship(deleteRule: .nullify, inverse: \Canvas.cloud)
    var canvases: [Canvas]

    init(name: String, cloudTags: [String]) {
        self.name = name
        self.cloudTags = cloudTags
        self.canvases = []
        self.createdOn = .now
    }
}
