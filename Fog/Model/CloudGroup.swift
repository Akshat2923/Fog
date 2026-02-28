//
//  CloudGroup.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/28/26.
//

import Foundation

struct CloudGroup: Identifiable {
    var id = UUID()
    var name: String?
    var groupDescription: String?
    var clouds: [Cloud]
    var sharedTags: [String]
}
