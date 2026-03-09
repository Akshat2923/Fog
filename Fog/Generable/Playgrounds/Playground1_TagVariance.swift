//
//  Playground_ThresholdDiagnosis.swift
//  Fog
//
//  Run this to see the actual similarity scores your notes produce.
//  The output tells you exactly what thresholds are realistic given
//  the tags the model actually generates.
//

import Foundation
import FoundationModels
import Playgrounds

@Generable
struct PDCanvasTags {
    @Guide(description: "Core topics in the note.", .maximumCount(3))
    let topics: [String]
    @Guide(description: "Specific things or concepts mentioned.", .maximumCount(3))
    let objects: [String]
}

func similarityScore(between lhs: Set<String>, and rhs: Set<String>) -> Double {
    let intersection = lhs.intersection(rhs)
    let overlapCount = intersection.count
    guard overlapCount > 0 else { return 0 }
    let unionCount = lhs.union(rhs).count
    guard unionCount > 0 else { return 0 }
    let jaccard = Double(overlapCount) / Double(unionCount)
    let relativeToSmaller = Double(overlapCount) / Double(min(lhs.count, rhs.count))
    // Current threshold gate
    let passesThreshold = overlapCount >= 2 || relativeToSmaller >= 0.6
    guard passesThreshold else { return 0 }
    return jaccard + (Double(overlapCount) * 0.05)
}

func rawJaccard(between lhs: Set<String>, and rhs: Set<String>) -> Double {
    let i = lhs.intersection(rhs).count
    guard i > 0 else { return 0 }
    return Double(i) / Double(lhs.union(rhs).count)
}

#Playground {
    let model = SystemLanguageModel(useCase: .contentTagging)

    // Replace these with actual notes from your app that should be grouping
    // but aren't. The more representative, the more useful the output.
    let shouldGroupPairs: [(String, String, String)] = [
        (
            "Bread baking",
            "Making sourdough bread. Feeding starter every 12 hours, scoring the loaf.",
            "Tried focaccia today. Olive oil, rosemary, 2 hour proof time."
        ),
        (
            "Cloud infra",
            "Studying AWS Solutions Architect exam. EC2 instance types, S3 storage classes.",
            "Setting up Kubernetes on Google Cloud. Auto-scaling and load balancers."
        ),
        (
            "iOS dev",
            "Debugging a race condition in Swift concurrency. Actor isolation not working.",
            "Building a new SwiftUI view for the settings screen. NavigationStack issues."
        ),
        (
            "Fitness",
            "New workout routine. Strength training 4 days a week, progressive overload.",
            "Tracking protein intake. Aiming for 180g per day to support muscle growth."
        )
    ]

    let shouldNotGroupPairs: [(String, String, String)] = [
        (
            "Apple ambiguity",
            "Watching the Apple keynote. MacBook Pro and M4 chip.",
            "Apple varieties at the farmer's market. Honeycrisp vs Fuji."
        ),
        (
            "Unrelated",
            "Dentist appointment Thursday 2pm. Ask about the crown.",
            "Finished reading Dune. The worldbuilding and political factions."
        )
    ]

    print("=== THRESHOLD DIAGNOSIS ===")
    print("Current gates: overlapCount >= 2 OR relativeToSmaller >= 0.6")
    print("Current thresholds: cloud join >= 0.25, new sibling >= 0.3\n")

    print("── SHOULD GROUP ──\n")
    for (label, noteA, noteB) in shouldGroupPairs {
        let sA = LanguageModelSession(model: model)
        let sB = LanguageModelSession(model: model)
        let rA = try await sA.respond(to: noteA, generating: PDCanvasTags.self)
        let rB = try await sB.respond(to: noteB, generating: PDCanvasTags.self)
        let tagsA = Set((rA.content.topics + rA.content.objects).map { $0.lowercased() })
        let tagsB = Set((rB.content.topics + rB.content.objects).map { $0.lowercased() })
        let overlap = tagsA.intersection(tagsB)
        let scored = similarityScore(between: tagsA, and: tagsB)
        let jaccard = rawJaccard(between: tagsA, and: tagsB)
        let relSmaller = overlap.count > 0 ? Double(overlap.count) / Double(min(tagsA.count, tagsB.count)) : 0

        print("[\(label)]")
        print("  A: \(tagsA.sorted())")
        print("  B: \(tagsB.sorted())")
        print("  overlap        : \(overlap.isEmpty ? "none" : overlap.sorted().joined(separator: ", "))")
        print("  raw jaccard    : \(String(format: "%.3f", jaccard))")
        print("  rel to smaller : \(String(format: "%.3f", relSmaller))")
        print("  passes gate    : \(overlap.count >= 2 || relSmaller >= 0.6 ? "✅ yes" : "❌ NO — scored as 0")")
        print("  final score    : \(String(format: "%.3f", scored))")
        print("  would join cloud (>=0.25): \(scored >= 0.25 ? "✅" : "❌")")
        print("  would pair sibling (>=0.3): \(scored >= 0.3 ? "✅" : "❌")")
        print()
    }

    print("── SHOULD NOT GROUP ──\n")
    for (label, noteA, noteB) in shouldNotGroupPairs {
        let sA = LanguageModelSession(model: model)
        let sB = LanguageModelSession(model: model)
        let rA = try await sA.respond(to: noteA, generating: PDCanvasTags.self)
        let rB = try await sB.respond(to: noteB, generating: PDCanvasTags.self)
        let tagsA = Set((rA.content.topics + rA.content.objects).map { $0.lowercased() })
        let tagsB = Set((rB.content.topics + rB.content.objects).map { $0.lowercased() })
        let overlap = tagsA.intersection(tagsB)
        let scored = similarityScore(between: tagsA, and: tagsB)

        print("[\(label)]")
        print("  A: \(tagsA.sorted())")
        print("  B: \(tagsB.sorted())")
        print("  overlap     : \(overlap.isEmpty ? "none ✅" : overlap.sorted().joined(separator: ", "))")
        print("  final score : \(String(format: "%.3f", scored))  \(scored == 0 ? "✅ correctly 0" : "⚠️ non-zero")")
        print()
    }

    print("=== WHAT TO LOOK FOR ===")
    print("If 'passes gate' is ❌ for things that should group:")
    print("  → The threshold gate (overlapCount >= 2) is too strict for 6-tag sets.")
    print("  → Fix: lower to overlapCount >= 1, rely on jaccard score for filtering instead.")
    print()
    print("If final score is 0 but raw jaccard > 0:")
    print("  → The gate is blocking valid pairs before scoring even happens.")
    print("  → Fix: remove the gate entirely, use jaccard directly with a lower threshold.")
}
