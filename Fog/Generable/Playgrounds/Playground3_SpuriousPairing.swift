//
//  Playground3_SpuriousPairing.swift
//  Fog
//
//  Tests the missing similarity floor for new cloud creation.
//  Completely unrelated notes should NOT form a cloud together.
//  Current code pairs the best-scoring sibling even if the score is near zero.
//

import Foundation
import FoundationModels
import Playgrounds

@Generable
struct P3CanvasTags {
    @Guide(
        description: "Core topics in the note, like 'machine learning' or 'vacation planning'.",
        .maximumCount(3)
    )
    let topics: [String]

    @Guide(
        description: "Specific things or concepts mentioned, like 'Python', 'Paris', or 'sourdough'.",
        .maximumCount(3)
    )
    let objects: [String]
}

#Playground {
    let model = SystemLanguageModel(useCase: .contentTagging)

    let unrelatedNotes = [
        "Dentist appointment on Thursday at 2pm. Need to ask about the crown on my back molar.",
        "Finished reading Dune. The worldbuilding is incredible, especially the political factions.",
        "My sourdough starter died again. Too much whole wheat flour killed the yeast culture.",
        "Debugging a race condition in my Swift concurrency code. The actor isolation isn't working.",
        "Grocery list: eggs, oat milk, arugula, parmesan, chicken thighs, lemons."
    ]

    func jaccardScore(_ a: Set<String>, _ b: Set<String>) -> Double {
        let intersection = a.intersection(b)
        guard !intersection.isEmpty else { return 0 }
        return Double(intersection.count) / Double(a.union(b).count)
    }

    print("=== SPURIOUS PAIRING TEST ===")
    print("None of these notes should group together.\n")

    var allTags: [(label: String, tags: Set<String>)] = []

    for note in unrelatedNotes {
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: note, generating: P3CanvasTags.self)
        let tags = Set((response.content.topics + response.content.objects).map { $0.lowercased() })
        let label = String(note.prefix(45)) + "..."
        allTags.append((label: label, tags: tags))
        print("'\(note.prefix(45))...'")
        print("  Tags: \(tags.sorted())\n")
    }

    print("--- Pairwise scores ---")
    print("Current code pairs the best score even if near-zero (no floor guard).\n")

    var foundSpurious = false
    for i in 0..<allTags.count {
        for j in (i + 1)..<allTags.count {
            let score = jaccardScore(allTags[i].tags, allTags[j].tags)
            if score > 0 {
                print("⚠️  '\(allTags[i].label)'")
                print("    + '\(allTags[j].label)'")
                print("    score: \(String(format: "%.3f", score)) — current code WOULD pair these")
                print()
                foundSpurious = true
            }
        }
    }

    if !foundSpurious {
        print("✅ No spurious pairs detected this run.")
    }

    print("💡 Fix: guard bestSiblingScore >= 0.3 before creating a new cloud.")
}
