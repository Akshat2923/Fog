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

    init(name: String, sharedTags: [String]) {
        self.name = name
        self.cloudTags = sharedTags
        self.canvases = []
        self.createdOn = .now
    }
}
