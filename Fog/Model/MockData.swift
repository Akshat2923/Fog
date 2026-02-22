//
//  MockData.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import Foundation
import SwiftData
import SwiftUI

struct MockData: PreviewModifier {
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }

    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: Canvas.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let canvas1 = Canvas(text: "Need to finish the Q4 report by Friday and sync with the team.")
        canvas1.title = "Q4 Report Deadline"
        canvas1.tags = ["work", "deadline", "report"]

        let canvas2 = Canvas(text: "Meeting with design team to discuss the launch timeline and assets.")
        canvas2.title = "Design Sync"
        canvas2.tags = ["work", "meeting", "design"]

        let canvas3 = Canvas(text: "Picked up groceries. Need to cook dinner tonight.")
        canvas3.title = "Grocery Run"
        canvas3.tags = ["personal", "food", "errand"]

        let workCloud = Cloud(name: "Work", sharedTags: ["work"])
        workCloud.canvases = [canvas1, canvas2]

        container.mainContext.insert(canvas1)
        container.mainContext.insert(canvas2)
        container.mainContext.insert(canvas3)
        container.mainContext.insert(workCloud)

        return container
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var mockData: Self = .modifier(MockData())
}
