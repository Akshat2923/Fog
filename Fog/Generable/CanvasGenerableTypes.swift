//
//  CanvasAITypes.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import Foundation
import FoundationModels

// generates tags to compare with other canvas to create a cloud or other clouds to join existing on
@Generable()
struct CanvasTags {
    @Guide(
        description: "The most important topics found in the text.",
        .maximumCount(3)
    )
    let topics: [String]
    
    @Guide(
        description: "The most important objects or concepts found in the text.",
        .maximumCount(3)
    )
    let objects: [String]
}

// if no cloud match we leave it "unassigned"
@Generable
struct CanvasTitle {
    @Guide(description: "A memorable, descriptive title for this note, 5 words or fewer.")
    let title: String
}

// when a new cloud gets generated we also generate the incoming canvas title to save a session
@Generable
struct CanvasAndCloudMetadata {
    @Guide(description: "A memorable, descriptive title for this note, 5 words or fewer.")
    let title: String
    
    @Guide(description: "A short, evocative name for this group of related notes, 1-3 words.")
    let cloudName: String
}

@Generable
struct CloudSummary {
    @Guide(description: "A 2-3 sentence summary of the common themes and key points across all the notes.")
    let summary: String
}
