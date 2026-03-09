//
//  CanvasProcessor.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import Foundation
import SwiftData
import FoundationModels
import Observation

@Observable
@MainActor
final class CanvasProcessor {
    private(set) var isProcessing = false
    private(set) var streamingSummary = ""
    private(set) var isStreamingSummary = false
    private(set) var notAvailableReason: String = ""
    var isModelAvailable: Bool { notAvailableReason.isEmpty }
    private(set) var userFacingErrorMessage: String?
    private(set) var cloudGroups: [CloudGroup] = []
    private(set) var isGeneratingGroups = false
    
    var error: Error?
    
    private let generalModel = SystemLanguageModel.default
    private let taggingModel = SystemLanguageModel(useCase: .contentTagging)
    init() {
        checkAvailability()
    }
    
    private enum CloudAssignment {
        case existingCloud(Cloud)
        case newCloud(Canvas)
        case unassigned
    }
    
    private(set) var streamingSuggestion = ""
    private(set) var isStreamingSuggestion = false
    private(set) var suggestionCanvasId: PersistentIdentifier?
    
    func checkAvailability() {
        switch SystemLanguageModel.default.availability {
        case .available:
            notAvailableReason = ""
        case .unavailable(.appleIntelligenceNotEnabled):
            notAvailableReason = "Enable Apple Intelligence in Settings to organize canvases automatically."
        case .unavailable(.deviceNotEligible):
            notAvailableReason = "Apple Intelligence is not available on this device. Canvases will not be automatically organized."
        case .unavailable(.modelNotReady):
            notAvailableReason = "Apple Intelligence is downloading. Canvases will be organized once it's ready."
        case .unavailable(let other):
            notAvailableReason = "Apple Intelligence unavailable: \(String(describing: other))"
        }
    }
    
    func processCanvas(_ canvas: Canvas, context: ModelContext) async {
        // make sure model is available
        guard case .available = generalModel.availability else { return }
        
        isProcessing = true
        
        error = nil
        
        defer { isProcessing = false }
        
        do {
            canvas.tags = try await generateTags(for: canvas)
            
            let assignment = try determineAssignment(for: canvas, context: context)
            switch assignment {
                
            case .existingCloud(let cloud):
                // Only grow cloud with tags that were already relevant to it
                let overlap = Set(canvas.tags).intersection(Set(cloud.cloudTags))
                cloud.cloudTags = Array(Set(cloud.cloudTags).union(overlap))
                if !cloud.canvases.contains(canvas) {
                    cloud.canvases.append(canvas)
                }
                try await streamTitle(into: canvas)
                
            case .newCloud(let sibling):
                let sharedTags = Array(Set(canvas.tags).intersection(Set(sibling.tags)))
                let newCloud = Cloud(name: "", cloudTags: sharedTags)
                context.insert(newCloud)
                newCloud.canvases = [canvas, sibling]
                try await streamTitleAndCloudName(into: canvas, cloud: newCloud, sibling: sibling)
                
            case .unassigned:
                try await streamTitle(into: canvas)
            }
            
            try context.save()
            
        } catch {
            self.error = error
            setUserFacingErrorMessage(from: error, operation: "organize your note")
            
        }
    }
    func rebuildClouds(context: ModelContext) async {
        guard case .available = generalModel.availability else { return }
        error = nil
        
        do {
            let allCanvases = try context.fetch(FetchDescriptor<Canvas>())
            for canvas in allCanvases {
                canvas.tags = []
                canvas.title = nil
            }
            try context.save()
            
            try context.delete(model: Cloud.self)
            try context.save()
            
            let canvases = try context.fetch(FetchDescriptor<Canvas>())
                .sorted { $0.createdOn < $1.createdOn }
            
            for canvas in canvases {
                await processCanvas(canvas, context: context)
            }
        } catch {
            self.error = error
        }
    }
    
    func streamSummary(for cloud: Cloud, context: ModelContext? = nil) async {
        guard case .available = generalModel.availability else { return }
        
        let existingSummary = cloud.summary ?? ""
        let existingSignature = cloud.summaryContentSignature ?? ""
        let contentSignature = cloudSummarySignature(for: cloud)
        if existingSignature == contentSignature,
           !existingSummary.isEmpty {
            streamingSummary = existingSummary
            isStreamingSummary = false
            return
        }
        
        streamingSummary = existingSummary
        isStreamingSummary = true
        error = nil
        userFacingErrorMessage = nil
        
        defer { isStreamingSummary = false }
        
        // Convert each canvas's AttributedString to plain String for the prompt.
        let canvasTexts = cloud.canvases
            .enumerated()
            .map { "Canvas \($0.offset + 1): \(String($0.element.text.characters.prefix(200)))" }
            .joined(separator: "\n\n")
        
        do {
            let session = LanguageModelSession(
                instructions: Instructions {
                    "You are an expert summarizer."
                    "Summarize the common themes across these notes in 2-3 sentences."
                }
            )
            
            let stream = session.streamResponse(
                generating: CloudSummary.self,
                includeSchemaInPrompt: false
            ) {
                "This cloud contains \(cloud.canvases.count) canvases:"
                canvasTexts
            }
            for try await partial in stream {
                if let summary = partial.content.summary {
                    streamingSummary = summary
                }
            }
            
            cloud.summary = streamingSummary
            cloud.summaryContentSignature = contentSignature
            try context?.save()
        } catch {
            self.error = error
            setUserFacingErrorMessage(from: error, operation: "generate a summary")
            
        }
    }
    
    func clearUserFacingError() {
        userFacingErrorMessage = nil
    }
    
    func prewarm() {
        LanguageModelSession().prewarm()
    }
    
    // Returns which of the three cases applies to the incoming canvas.
    private func determineAssignment(for canvas: Canvas, context: ModelContext) throws -> CloudAssignment {
        let canvasTags = Set(canvas.tags)
        
        guard !canvasTags.isEmpty else { return .unassigned }
        
        let allClouds = try context.fetch(FetchDescriptor<Cloud>())
        var bestCloud: Cloud?
        var bestCloudScore = 0.0
        for cloud in allClouds {
            let score = similarityScore(between: canvasTags, and: Set(cloud.cloudTags))
            if score > bestCloudScore {
                bestCloudScore = score
                bestCloud = cloud
            }
        }
        
        if let bestCloud, bestCloudScore >= 0.25 {
            // Only union the overlapping tags — don't let cloud absorb unrelated tags
            let overlap = canvasTags.intersection(Set(bestCloud.cloudTags))
            bestCloud.cloudTags = Array(Set(bestCloud.cloudTags).union(overlap))
            return .existingCloud(bestCloud)
        }
        
        // No existing cloud matched. Look for an unassigned canvas to pair with.
        let allCanvases = try context.fetch(FetchDescriptor<Canvas>())
        let unassigned = allCanvases.filter {
            $0.cloud == nil       // not already in a cloud
            && $0 !== canvas      // not the same canvas we're processing
            && !$0.tags.isEmpty   // has tags to compare against
        }
        
        var bestSibling: Canvas?
        var bestSiblingScore = 0.0
        for other in unassigned {
            let score = similarityScore(between: canvasTags, and: Set(other.tags))
            if score > bestSiblingScore {
                bestSiblingScore = score
                bestSibling = other
            }
        }
        
        if let bestSibling {
            return .newCloud(bestSibling)
        }
        
        return .unassigned
    }
    
    // Generates a title only. Used when joining an existing cloud or staying unassigned.
    private func streamTitle(into canvas: Canvas) async throws {
        let session = LanguageModelSession(
            instructions: Instructions {
                "You are an expert note organizer."
                "Generate a short title that captures the main topic of the note."
            }
        )
        let text = String(canvas.text.characters)
        let stream = session.streamResponse(generating: CanvasTitle.self) {
            "Here is the canvas to title:"
            text
        }
        for try await partial in stream {
            if let title = partial.content.title {
                canvas.title = title
            }
        }
    }
    
    // Used only when a new cloud is being formed — sibling provides naming context.
    private func streamTitleAndCloudName(into canvas: Canvas, cloud: Cloud, sibling: Canvas) async throws {
        let canvasText = String(canvas.text.characters)
        let siblingText = String(sibling.text.characters.prefix(200))
        
        // Session 1 — title only
        let titleSession = LanguageModelSession(
            instructions: Instructions {
                "You are an expert note organizer."
                "Generate a short title, 2-5 words, for the note below."
            }
        )
        let titleStream = titleSession.streamResponse(generating: CanvasTitle.self) {
            "Note: \(canvasText)"
        }
        for try await partial in titleStream {
            if let title = partial.content.title {
                canvas.title = title
            }
        }
        
        // Session 2 — cloud name only, informed by both titles
        let cloudSession = LanguageModelSession(
            instructions: Instructions {
                "You are an expert note organizer."
                "Generate a short group name, 1-3 words, that captures what two notes have in common."
            }
        )
        let cloudStream = cloudSession.streamResponse(generating: CloudName.self) {
            "Note 1: \(canvas.title ?? canvasText)"
            "Note 2: \(sibling.title ?? siblingText)"
        }
        for try await partial in cloudStream {
            if let name = partial.content.cloudName {
                cloud.name = name
            }
        }
    }
    
    // Generates tags using the specialized content tagging model.
    // This is always a separate session because it uses a different model entirely.
    private func generateTags(for canvas: Canvas) async throws -> [String] {
        let text = String(canvas.text.characters)
        let session = LanguageModelSession(
            model: taggingModel,
            instructions: text.count < 100
            ? "Provide the 3 most significant topics."
            : "Provide the 3 most significant topics and 3 most significant objects."
        )
        let response = try await session.respond(
            to: String(canvas.text.characters),
            generating: CanvasTags.self
        )
        
        return Array(Set(
            (response.content.topics + response.content.objects)
                .map { $0.lowercased() }
        ))
    }
    
    private func cloudSummarySignature(for cloud: Cloud) -> String {
        cloud.canvases
            .sorted(by: { (lhs: Canvas, rhs: Canvas) in
                if lhs.createdOn == rhs.createdOn {
                    return lhs.updatedOn < rhs.updatedOn
                }
                return lhs.createdOn < rhs.createdOn
            })
            .map {
                "\($0.createdOn.timeIntervalSinceReferenceDate):\($0.updatedOn.timeIntervalSinceReferenceDate)"
            }
            .joined(separator: "|")
    }
    
    private func similarityScore(
        between lhs: Set<String>,
        and rhs: Set<String>
    ) -> Double {
        let intersection = lhs.intersection(rhs)
        let overlapCount = intersection.count
        
        guard overlapCount > 0 else { return 0 }
        
        let unionCount = lhs.union(rhs).count
        guard unionCount > 0 else { return 0 }
        
        let jaccard = Double(overlapCount) / Double(unionCount)
        let relativeToSmaller = Double(overlapCount) / Double(min(lhs.count, rhs.count))
        
        // Require meaningful overlap, not just any single shared tag.
        let passesThreshold = overlapCount >= 2 || relativeToSmaller >= 0.6
        guard passesThreshold else { return 0 }
        
        // Favor denser overlap while still rewarding absolute evidence.
        return jaccard + (Double(overlapCount) * 0.05)
    }
    
    
    func buildCloudGroups(from clouds: [Cloud]) async {
        guard clouds.count >= 2 else {
            cloudGroups = []
            return
        }
        
        let newGroups = computeGroups(from: clouds)
        
        // Preserve existing names/descriptions for groups that haven't changed.
        var updatedGroups = newGroups
        for i in updatedGroups.indices {
            let newSig = groupSignature(updatedGroups[i])
            if let existing = cloudGroups.first(where: { groupSignature($0) == newSig }) {
                updatedGroups[i].id = existing.id
                updatedGroups[i].name = existing.name
                updatedGroups[i].groupDescription = existing.groupDescription
            }
        }
        cloudGroups = updatedGroups
        
        guard case .available = generalModel.availability else { return }
        
        let needsGeneration = cloudGroups.enumerated().filter { $0.element.name == nil }
        guard !needsGeneration.isEmpty else { return }
        
        isGeneratingGroups = true
        defer { isGeneratingGroups = false }
        
        for (i, _) in needsGeneration {
            do {
                try await streamGroupMetadata(at: i)
            } catch {
                cloudGroups[i].name = cloudGroups[i].sharedTags.prefix(3).joined(separator: " · ")
            }
        }
    }
    
    private func groupSignature(_ group: CloudGroup) -> String {
        group.clouds.map(\.name).sorted().joined(separator: "|")
    }
    
    private func computeGroups(from clouds: [Cloud]) -> [CloudGroup] {
        let safeClouds = clouds.filter { !$0.cloudTags.isEmpty }
        let n = safeClouds.count
        guard n >= 2 else { return [] }
        var parent = Array(0..<n)
        
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
            return x
        }
        
        func union(_ a: Int, _ b: Int) {
            let ra = find(a), rb = find(b)
            if ra != rb { parent[ra] = rb }
        }
        
        for i in 0..<n {
            for j in (i + 1)..<n {
                let tagsA = Set(safeClouds[i].cloudTags)
                let tagsB = Set(safeClouds[j].cloudTags)
                let shared = tagsA.intersection(tagsB)
                let relativeOverlap = Double(shared.count) / Double(min(tagsA.count, tagsB.count))
                if shared.count >= 2 || relativeOverlap >= 0.5 {
                    union(i, j)
                }
            }
        }
        
        var groupMap: [Int: [Int]] = [:]
        for i in 0..<n {
            groupMap[find(i), default: []].append(i)
        }
        
        return groupMap.values
            .filter { $0.count >= 2 }
            .map { indices in
                let groupClouds = indices.map { safeClouds[$0] }
                let sharedTags = groupClouds
                    .reduce(Set(groupClouds[0].cloudTags)) { $0.intersection(Set($1.cloudTags)) }
                return CloudGroup(clouds: groupClouds, sharedTags: Array(sharedTags))
            }
            .sorted { $0.clouds.count > $1.clouds.count }
    }
    
    private func streamGroupMetadata(at index: Int) async throws {
        let group = cloudGroups[index]
        
        let cloudSummaries = group.clouds
            .map { "Cloud '\($0.name)' — tags: \($0.cloudTags.joined(separator: ", "))" }
            .joined(separator: "\n")
        let sharedTagsText = group.sharedTags.joined(separator: ", ")
        
        // Session 1 — name only
        let nameSession = LanguageModelSession(
            instructions: Instructions {
                "You are an expert note organizer."
                "Generate a short group name, 1-3 words, for a collection of related note groups."
            }
        )
        let nameStream = nameSession.streamResponse(generating: CloudGroupName.self) {
            "These note groups share these tags: \(sharedTagsText)"
            cloudSummaries
        }
        for try await partial in nameStream {
            if let name = partial.content.name {
                cloudGroups[index].name = name
            }
        }
        
        // Session 2 — description only, can reference the name we just generated
        let descSession = LanguageModelSession(
            instructions: Instructions {
                "You are an expert note organizer."
                "Write one sentence describing what a collection of note groups have in common."
            }
        )
        let descStream = descSession.streamResponse(generating: CloudGroupDescription.self) {
            "Group name: \(cloudGroups[index].name ?? sharedTagsText)"
            "Shared tags: \(sharedTagsText)"
            cloudSummaries
        }
        for try await partial in descStream {
            if let desc = partial.content.groupDescription {
                cloudGroups[index].groupDescription = desc
            }
        }
    }
    
    
    private func setUserFacingErrorMessage(from error: Error, operation: String) {
        guard let generationError = error as? LanguageModelSession.GenerationError else {
            userFacingErrorMessage = "Couldn't \(operation): \(error.localizedDescription)"
            return
        }
        
        let baseMessage: String
        switch generationError {
        case .guardrailViolation:
            baseMessage = "Couldn't \(operation) because the request was blocked by safety guardrails."
        case .decodingFailure:
            baseMessage = "Couldn't \(operation) because the model returned an unexpected response format."
        case .rateLimited:
            baseMessage = "Couldn't \(operation) right now because the model is rate limited. Please try again in a moment."
        case .exceededContextWindowSize(_):
            baseMessage = "Couldn't \(operation): \(generationError.localizedDescription)"
            
        case .assetsUnavailable(_):
            baseMessage = "Couldn't \(operation): \(generationError.localizedDescription)"
            
        case .unsupportedGuide(_):
            baseMessage = "Couldn't \(operation): \(generationError.localizedDescription)"
            
        case .unsupportedLanguageOrLocale(_):
            baseMessage = "Couldn't \(operation): \(generationError.localizedDescription)"
            
        case .concurrentRequests(_):
            baseMessage = "Couldn't \(operation): \(generationError.localizedDescription)"
            
        case .refusal(_, _):
            baseMessage = "Couldn't \(operation): \(generationError.localizedDescription)"
            
        @unknown default:
            baseMessage = "Couldn't \(operation): \(generationError.localizedDescription)"
        }
        
        let failureReason = generationError.failureReason ?? ""
        let recoverySuggestion = generationError.recoverySuggestion ?? ""
        let extras = [failureReason, recoverySuggestion]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        
        userFacingErrorMessage = extras.isEmpty ? baseMessage : "\(baseMessage)\n\(extras)"
    }
}
