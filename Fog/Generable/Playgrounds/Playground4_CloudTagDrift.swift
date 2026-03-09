//
//  Playground4_CloudTagDrift.swift
//  Fog
//
//  Simulates what happens to cloud tags over 5 sequential canvas additions.
//  A cloud that starts as "fitness" slowly drifts toward "food" via union(overlap).
//  Watch the cloud identity erode with each new note added.
//

import Foundation
import FoundationModels
import Playgrounds

@Generable
struct P4CanvasTags {
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

    // Starts clearly fitness. Each note incrementally drifts the topic.
    let sequentialNotes = [
        "Starting a new workout routine. Focusing on strength training and progressive overload.",
        "Tracking my calories and protein intake to support muscle growth.",
        "Meal prepping for the week. Chicken, rice, and broccoli for macros.",
        "New recipe for high-protein overnight oats with banana and almond butter.",
        "Trying a new sourdough recipe. The fermentation process takes 48 hours."
    ]

    func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        let i = a.intersection(b)
        guard !i.isEmpty else { return 0 }
        return Double(i.count) / Double(a.union(b).count)
    }

    print("=== CLOUD TAG DRIFT TEST ===\n")

    // Notes 1 + 2 form the initial cloud
    let s1 = LanguageModelSession(model: model)
    let s2 = LanguageModelSession(model: model)

    let r1 = try await s1.respond(to: sequentialNotes[0], generating: P4CanvasTags.self)
    let r2 = try await s2.respond(to: sequentialNotes[1], generating: P4CanvasTags.self)

    let tags1 = Set((r1.content.topics + r1.content.objects).map { $0.lowercased() })
    let tags2 = Set((r2.content.topics + r2.content.objects).map { $0.lowercased() })

    var cloudTags = tags1.intersection(tags2)
    let originalCloudTags = cloudTags

    print("Cloud formed from notes 1 + 2")
    print("  Note 1 tags        : \(tags1.sorted())")
    print("  Note 2 tags        : \(tags2.sorted())")
    print("  Initial cloud tags : \(cloudTags.sorted())\n")

    // Add notes 3–5 using the current union(overlap) logic
    for i in 2..<sequentialNotes.count {
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: sequentialNotes[i], generating: P4CanvasTags.self)
        let newTags = Set((response.content.topics + response.content.objects).map { $0.lowercased() })

        let overlap = newTags.intersection(cloudTags)
        let scoreBefore = jaccard(newTags, cloudTags)
        cloudTags = cloudTags.union(overlap) // current logic in CanvasProcessor

        print("Adding note \(i + 1): '\(sequentialNotes[i].prefix(55))...'")
        print("  New note tags      : \(newTags.sorted())")
        print("  Overlap with cloud : \(overlap.isEmpty ? "none ⚠️" : overlap.sorted().joined(separator: ", "))")
        print("  Join score         : \(String(format: "%.3f", scoreBefore))")
        print("  Cloud tags now     : \(cloudTags.sorted())")
        print("  Drift (added tags) : \(cloudTags.subtracting(originalCloudTags).sorted())\n")
    }

    print("💡 If cloud tags drifted significantly, unrelated notes will incorrectly join.")
    print("   Fix: freeze cloudTags at formation; use them read-only for matching.")
}
