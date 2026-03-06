//
//  CanvasAITypes.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import Foundation
import FoundationModels


@Generable
struct CanvasTags {
    @Guide(
        description: "Core topics in the note, like 'machine learning', 'vacation planning', or 'recipe'.",
        .maximumCount(3)
    )
    let topics: [String]

    @Guide(
        description: "Specific things, people, or concepts mentioned, like 'Python', 'Paris', or 'sourdough bread'.",
        .maximumCount(3)
    )
    let objects: [String]
}

@Generable
struct CanvasTitle {
    @Guide(description: "A concise title for the note, 2–5 words, like 'Weekly Grocery Run' or 'App Launch Ideas'.")
    let title: String
}


@Generable
struct CloudName {
    @Guide(description: "A short thematic name for this group, 1–3 words, like 'Fitness' or 'Travel Plans'.")
    let cloudName: String
}

@Generable
struct CloudSummary {
    @Guide(description: "A brief 2–3 sentence summary highlighting the shared themes, key ideas, and connections across all the notes in this collection.")
    let summary: String
}

@Generable
struct CloudGroupName {
    @Guide(description: "A short thematic name, 1–3 words, like 'Creative Projects' or 'Daily Life'.")
    let name: String
}

@Generable
struct CloudGroupDescription {
    @Guide(description: "One sentence describing what these groups have in common, like 'Collections centered on health and fitness.'")
    let groupDescription: String
}
