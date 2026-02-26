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
    
    var error: Error?
    
    private let generalModel = SystemLanguageModel.default
    private let taggingModel = SystemLanguageModel(useCase: .contentTagging)
    
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
                
                // clouds are ever changing over time
                let overlap = Set(canvas.tags).intersection(Set(cloud.cloudTags))
                cloud.cloudTags = Array(Set(cloud.cloudTags).union(overlap))
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
        }
    }
    
    func streamSummary(for cloud: Cloud) async {
        guard case .available = generalModel.availability else { return }
        streamingSummary = ""
        isStreamingSummary = true
        error = nil
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
        } catch {
            self.error = error
        }
    }
    
    func prewarm() {
        LanguageModelSession().prewarm()
    }
    
    // Returns which of the three cases applies to the incoming canvas.
    private func determineAssignment(for canvas: Canvas, context: ModelContext) throws -> CloudAssignment {
        let canvasTags = Set(canvas.tags)
        
        guard !canvasTags.isEmpty else { return .unassigned }
        
        let allClouds = try context.fetch(FetchDescriptor<Cloud>())
        for cloud in allClouds {
            // is there an intersection in both sets, and not empty
            if !canvasTags.intersection(Set(cloud.cloudTags)).isEmpty {
                return .existingCloud(cloud)
            }
        }
        
        // No existing cloud matched. Look for an unassigned canvas to pair with.
        let allCanvases = try context.fetch(FetchDescriptor<Canvas>())
        let unassigned = allCanvases.filter {
            $0.cloud == nil       // not already in a cloud
            && $0 !== canvas      // not the same canvas we're processing
            && !$0.tags.isEmpty   // has tags to compare against
        }
        
        for other in unassigned {
            if !canvasTags.intersection(Set(other.tags)).isEmpty {
                return .newCloud(other)
            }
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
    
    
}
