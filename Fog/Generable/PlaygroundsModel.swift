//
//  PlaygroundsModel.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/4/26.
//

import FoundationModels
import Playgrounds


#Playground {
    
    let processor = CanvasProcessor()
    
    let testText = """
    Building a SwiftUI iOS app that automatically organizes notes.
    I'm experimenting with Apple's Foundation Models framework,
    language model sessions, and automatic tagging for content grouping.
    """
    
    let session = LanguageModelSession(
        model: SystemLanguageModel(useCase: .contentTagging),
        instructions: Instructions {
            "You are analyzing a note in Fog, a note-taking app."
            """
            Identify the core topics and specific concepts in this note \
            so it can be automatically grouped with similar notes.
            """
        }
    )
    
    let response = try await session.respond(
        to: testText,
        generating: CanvasTags.self
    )
    
    let tags = (response.content.topics + response.content.objects)
        .map { $0.lowercased() }
    
    print(tags)
}

#Playground {
    
    let notes = [
        """
        Learning SwiftUI layouts and navigation stacks for my iOS app.
        """,
        
        """
        Experimenting with Apple's Foundation Models framework
        to automatically organize notes using AI.
        """,
        
        """
        Practicing Python programming and algorithms for interviews.
        """
    ]
    
    let model = SystemLanguageModel(useCase: .contentTagging)
    
    for note in notes {
        let session = LanguageModelSession(model: model)
        
        let response = try await session.respond(
            to: note,
            generating: CanvasTags.self
        )
        
        let tags = (response.content.topics + response.content.objects)
        print("\nNOTE:")
        print(note)
        print("TAGS:", tags)
    }
}
