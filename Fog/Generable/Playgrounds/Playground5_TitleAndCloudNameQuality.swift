////
////  Playground5_TitleAndCloudNameQuality.swift
////  Fog
////
////  Qualitative test for generated titles and cloud names.
////  Read the output and judge whether names are specific and useful,
////  or generic and forgettable (e.g. "Tech Stuff", "Notes").
////
//
//import FoundationModels
//import Playgrounds
//
//@Generable
//struct P5CanvasTitle {
//    @Guide(description: "A concise title for the note, 2–5 words, like 'Weekly Grocery Run' or 'App Launch Ideas'.")
//    let title: String
//}
//
//@Generable
//struct P5CloudName {
//    @Guide(description: "A short thematic name for this group, 1–3 words, like 'Fitness' or 'Travel Plans'.")
//    let cloudName: String
//}
//
//#Playground {
//    let notePairs: [(noteA: String, noteB: String)] = [
//        (
//            noteA: "Need to refactor the authentication module. The JWT token refresh logic is brittle and causing random logouts.",
//            noteB: "Found a memory leak in the image caching layer. Instruments shows 200MB growing unbounded after scrolling."
//        ),
//        (
//            noteA: "Planning a solo backpacking trip through Patagonia in November. Need to research gear and permits.",
//            noteB: "Booked flights to Buenos Aires. Arriving November 3rd, need to figure out bus routes south."
//        ),
//        (
//            noteA: "Trying to get better at watercolor. Practicing wet-on-wet technique for sky gradients.",
//            noteB: "Picked up a set of Winsor & Newton gouache paints. Experimenting with opacity on toned paper."
//        )
//    ]
//
//    print("=== TITLE & CLOUD NAME QUALITY TEST ===\n")
//
//    for pair in notePairs {
//        let titleSession = LanguageModelSession(
//            instructions: Instructions {
//                "You are an expert note organizer."
//                "Generate a short title, 2-5 words, for the note below."
//            }
//        )
//        let titleStream = titleSession.streamResponse(generating: P5CanvasTitle.self) {
//            "Note: \(pair.noteA)"
//        }
//        var titleA = ""
//        for try await partial in titleStream {
//            if let t = partial.content.title { titleA = t }
//        }
//
//        let cloudSession = LanguageModelSession(
//            instructions: Instructions {
//                "You are an expert note organizer."
//                "Generate a short group name, 1-3 words, that captures what two notes have in common."
//            }
//        )
//        let cloudStream = cloudSession.streamResponse(generating: P5CloudName.self) {
//            "Note 1: \(pair.noteA.prefix(120))"
//            "Note 2: \(pair.noteB.prefix(120))"
//        }
//        var cloudName = ""
//        for try await partial in cloudStream {
//            if let n = partial.content.cloudName { cloudName = n }
//        }
//
//        print("Note A : '\(pair.noteA.prefix(65))...'")
//        print("  Title      : \"\(titleA)\"")
//        print("  Cloud name : \"\(cloudName)\"")
//        print("Note B : '\(pair.noteB.prefix(65))...'\n")
//    }
//
//    print("✅ Good: specific names like \"iOS Bug Fixes\", \"Patagonia Trip\", \"Watercolor Practice\"")
//    print("❌ Bad : generic names like \"Tech\", \"Travel\", \"Art\"")
//}
