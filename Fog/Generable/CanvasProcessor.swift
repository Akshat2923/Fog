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
                // existing cloud, canvas only needs a title
                let result = try await generateTitle(for: canvas)
                canvas.title = result.title
                
                // Keep cloud tags evolving as new canvases are added.
                cloud.cloudTags = Array(Set(cloud.cloudTags).union(Set(canvas.tags)))
                cloud.canvases.append(canvas)
                
            case .newCloud(let sibling):
                let result = try await generateTitleAndCloudName(for: canvas, sibling: sibling)
                canvas.title = result.title
                
                // The sharedTags are what the two canvases have in common
                let sharedTags = Array(Set(canvas.tags).intersection(Set(sibling.tags)))
                let newCloud = Cloud(name: result.cloudName, cloudTags: sharedTags)
                
                context.insert(newCloud)
                newCloud.canvases = [canvas, sibling]
                
            case .unassigned:
                let result = try await generateTitle(for: canvas)
                canvas.title = result.title
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
        userFacingErrorMessage = nil
        
        do {
            let canvases = try context.fetch(FetchDescriptor<Canvas>())
                .sorted { $0.createdOn < $1.createdOn }
            
            for canvas in canvases {
                await processCanvas(canvas, context: context)
            }
        } catch {
            self.error = error
            setUserFacingErrorMessage(from: error, operation: "rebuild clouds")
            
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
            .map { "Canvas \($0.offset + 1): \(String($0.element.text.characters.prefix(500)))" }
            .joined(separator: "\n\n")
        
        do {
            
            let session = LanguageModelSession(
                instructions: "Summarize the common themes and key points across these notes in 2-3 concise sentences."
            )
            
            let stream = session.streamResponse(
                generating: CloudSummary.self,
                includeSchemaInPrompt: false
            ) {
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
        
        if let bestCloud {
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
    private func generateTitle(for canvas: Canvas) async throws -> CanvasTitle {
        let session = LanguageModelSession(
            instructions: "You are a concise assistant for a note-taking app. Generate a short title that captures the essence of the note."
        )
        let response = try await session.respond(
            to: String(canvas.text.characters),
            generating: CanvasTitle.self
        )
        return response.content
    }
    
    // Used only when a new cloud is being formed — sibling provides naming context.
    private func generateTitleAndCloudName(for canvas: Canvas, sibling: Canvas) async throws -> CanvasAndCloudMetadata {
        let session = LanguageModelSession(
            instructions: "You are a concise assistant for a note-taking app. Generate a title for the new note and a group name that captures what both notes have in common."
        )
        let prompt = """
                New note:
                \(String(canvas.text.characters))
                
                Similar existing note:
                \(String(sibling.text.characters.prefix(200)))
                """
        let response = try await session.respond(
            to: prompt,
            generating: CanvasAndCloudMetadata.self
        )
        return response.content
    }
    
    // Generates tags using the specialized content tagging model.
    // This is always a separate session because it uses a different model entirely.
    private func generateTags(for canvas: Canvas) async throws -> [String] {
        let session = LanguageModelSession(
            model: taggingModel,
            instructions: "Identify the most significant topics and concepts."
        )
        let response = try await session.respond(
            to: String(canvas.text.characters),
            generating: CanvasTags.self
        )
        
        return (response.content.topics + response.content.objects)
            .map { $0.lowercased() }
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
    
    /// Returns 0 for "not similar enough", otherwise a score where larger is better.
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
