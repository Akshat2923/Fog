//
//  Playground6_UnionFindBug.swift
//  Fog
//
//  Pure logic test — no model needed, runs instantly.
//  Directly demonstrates the safeClouds vs clouds index mismatch in computeGroups().
//  The buggy version compares the wrong clouds; the fixed version compares correctly.
//

import Playgrounds

struct MockCloud {
    let name: String
    let tags: [String]
}

#Playground {
    print("=== UNION-FIND INDEX BUG TEST ===\n")

    // Cloud B and E are empty — they get filtered into safeClouds,
    // but current code still indexes into the full allClouds array.
    let allClouds = [
        MockCloud(name: "Cloud A", tags: ["swift", "ios", "xcode"]),
        MockCloud(name: "Cloud B", tags: []),           // empty — filtered out
        MockCloud(name: "Cloud C", tags: ["swift", "concurrency"]),
        MockCloud(name: "Cloud D", tags: ["cooking", "recipes"]),
        MockCloud(name: "Cloud E", tags: [])            // empty — filtered out
    ]

    let safeClouds = allClouds.filter { !$0.tags.isEmpty }

    print("All clouds  (\(allClouds.count)) : \(allClouds.map(\.name))")
    print("Safe clouds (\(safeClouds.count)) : \(safeClouds.map(\.name))")
    print()

    // ❌ Buggy — iterates safeClouds.count but indexes into allClouds
    print("--- ❌ Buggy version (mirrors current computeGroups code) ---")
    let n = safeClouds.count
    for i in 0..<n {
        for j in (i + 1)..<n {
            let tagsA = Set(allClouds[i].tags)   // BUG: should be safeClouds[i]
            let tagsB = Set(allClouds[j].tags)   // BUG: should be safeClouds[j]
            let shared = tagsA.intersection(tagsB)
            let warning = (allClouds[i].tags.isEmpty || allClouds[j].tags.isEmpty) ? " ⚠️ comparing an empty cloud!" : ""
            print("  allClouds[\(i)] '\(allClouds[i].name)' vs allClouds[\(j)] '\(allClouds[j].name)'\(warning)")
            print("  Shared: \(shared.isEmpty ? "none" : shared.sorted().joined(separator: ", "))")
        }
    }

    print()

    // ✅ Fixed — both iteration and indexing use safeClouds
    print("--- ✅ Fixed version ---")
    for i in 0..<n {
        for j in (i + 1)..<n {
            let tagsA = Set(safeClouds[i].tags)
            let tagsB = Set(safeClouds[j].tags)
            let shared = tagsA.intersection(tagsB)
            print("  safeClouds[\(i)] '\(safeClouds[i].name)' vs safeClouds[\(j)] '\(safeClouds[j].name)'")
            print("  Shared: \(shared.isEmpty ? "none" : shared.sorted().joined(separator: ", "))")
        }
    }

    print()
    print("💡 Fix in computeGroups():")
    print("   Change: let tagsA = Set(clouds[i].cloudTags)")
    print("   To    : let tagsA = Set(safeClouds[i].cloudTags)")
    print("   Same for clouds[j] → safeClouds[j]")
}
