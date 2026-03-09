//
//  Playground2_SemanticSimilarity.swift
//  Fog
//
//  Tests the core tagging problem: specific tags never overlap across related notes.
//  Compares your current approach (specific terms) against a category-aware approach
//  that forces the model to also emit broad category tags that enable grouping.
//

import Foundation
import FoundationModels
import Playgrounds

// --- Current approach: specific topics + objects ---
@Generable
struct P2CurrentTags {
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

// --- Proposed fix: force a broad category + specific terms ---
// The category must be a single generalizing word or short phrase.
// This is what creates overlap between "sourdough" and "focaccia" notes.
@Generable
struct P2ImprovedTags {
    @Guide(
        description: """
        The single broadest category this note belongs to.
        Must be a general domain like 'baking', 'cloud computing', 'fitness', 'travel', 'ios development'.
        Never use specific product names or proper nouns here.
        """,
        .maximumCount(2)
    )
    let categories: [String]

    @Guide(
        description: "More specific topics within that category, like 'sourdough', 'EC2', 'strength training'.",
        .maximumCount(3)
    )
    let specifics: [String]
}

#Playground {
    let model = SystemLanguageModel(useCase: .contentTagging)

    let notePairs: [(label: String, noteA: String, noteB: String)] = [
        (
            label: "Bread notes (should group)",
            noteA: "Making sourdough bread at home. Need to feed the starter every 12 hours and score the loaf before baking.",
            noteB: "Tried a new focaccia recipe today. Used olive oil and rosemary. The dough needs 2 hours to proof."
        ),
        (
            label: "Cloud infra notes (should group)",
            noteA: "Studying for my AWS Solutions Architect exam. Reviewing EC2 instance types and S3 storage classes.",
            noteB: "Setting up a Kubernetes cluster on Google Cloud. Configured auto-scaling and load balancers."
        ),
        (
            label: "Apple ambiguity (should NOT group)",
            noteA: "Watching the Apple keynote. Excited about the new MacBook Pro and M4 chip announcement.",
            noteB: "Reading about apple varieties at the farmer's market. Honeycrisp vs Fuji for baking pies."
        )
    ]

    func jaccardScore(_ a: Set<String>, _ b: Set<String>) -> Double {
        let i = a.intersection(b)
        guard !i.isEmpty else { return 0 }
        return Double(i.count) / Double(a.union(b).count)
    }

    func wouldGroup(_ a: Set<String>, _ b: Set<String>) -> Bool {
        let overlap = a.intersection(b)
        return jaccardScore(a, b) >= 0.25 || overlap.count >= 2
    }

    print("=== CURRENT vs IMPROVED TAGGING ===\n")

    for pair in notePairs {
        // Current approach
        let curA = LanguageModelSession(model: model)
        let curB = LanguageModelSession(model: model)
        let curRespA = try await curA.respond(to: pair.noteA, generating: P2CurrentTags.self)
        let curRespB = try await curB.respond(to: pair.noteB, generating: P2CurrentTags.self)
        let curTagsA = Set((curRespA.content.topics + curRespA.content.objects).map { $0.lowercased() })
        let curTagsB = Set((curRespB.content.topics + curRespB.content.objects).map { $0.lowercased() })
        let curOverlap = curTagsA.intersection(curTagsB)
        let curScore = jaccardScore(curTagsA, curTagsB)

        // Improved approach
        let impA = LanguageModelSession(model: model)
        let impB = LanguageModelSession(model: model)
        let impRespA = try await impA.respond(to: pair.noteA, generating: P2ImprovedTags.self)
        let impRespB = try await impB.respond(to: pair.noteB, generating: P2ImprovedTags.self)
        let impTagsA = Set((impRespA.content.categories + impRespA.content.specifics).map { $0.lowercased() })
        let impTagsB = Set((impRespB.content.categories + impRespB.content.specifics).map { $0.lowercased() })
        let impOverlap = impTagsA.intersection(impTagsB)
        let impScore = jaccardScore(impTagsA, impTagsB)

        print("[\(pair.label)]")
        print("  CURRENT  A: \(curTagsA.sorted())")
        print("  CURRENT  B: \(curTagsB.sorted())")
        print("  overlap: \(curOverlap.isEmpty ? "none" : curOverlap.sorted().joined(separator: ", "))  score: \(String(format: "%.3f", curScore))  group: \(wouldGroup(curTagsA, curTagsB) ? "✅" : "❌")")
        print()
        print("  IMPROVED A: \(impTagsA.sorted())")
        print("  IMPROVED B: \(impTagsB.sorted())")
        print("  overlap: \(impOverlap.isEmpty ? "none" : impOverlap.sorted().joined(separator: ", "))  score: \(String(format: "%.3f", impScore))  group: \(wouldGroup(impTagsA, impTagsB) ? "✅" : "❌")")
        print("  ─────────────────────────────────────────")
        print()
    }

    print("If IMPROVED fixes pairs 1+2 while keeping pair 3 apart,")
    print("replace P2CurrentTags with P2ImprovedTags in CanvasAITypes.swift")
    print("and update generateTags() in CanvasProcessor to use .categories + .specifics")
}
