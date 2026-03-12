//
//  PileManager.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/11/26.
//

import SwiftUI
import SwiftData

@Observable
@MainActor
final class PileManager {
    /// The currently active pile. Nil only briefly before first load.
    private(set) var activePile: Pile?

    /// Persisted ID of the active pile so it survives app restarts.
    @ObservationIgnored
    @AppStorage("activePileID") private var activePileIDString: String = ""

    /// These AppStorage keys are read by MeshGradientBackground and the rest of
    /// the app. We write to them whenever the active pile changes so the UI
    /// stays in sync without requiring every view to know about Pile.
    @ObservationIgnored
    @AppStorage("accentColor") private var storedAccentColor: String = ""
    @ObservationIgnored
    @AppStorage("useFullTint") private var storedUseFullTint: Bool = false
    @ObservationIgnored
    @AppStorage("meshOpacityScale") private var storedMeshOpacityScale: Double = 1.0
    @ObservationIgnored
    @AppStorage("rainbowRave") private var storedRainbowRave: Bool = false

    // MARK: - Lifecycle

    /// Called once on app launch with the full list of piles from SwiftData.
    func loadActivePile(from piles: [Pile], context: ModelContext) {
        if piles.isEmpty {
            // First launch — create the default pile seeded from existing AppStorage values
            let defaultPile = Pile(name: "Personal", isDefault: true)
            // Carry over any theme the user already set before Piles existed
            if !storedAccentColor.isEmpty {
                defaultPile.accentColorRaw = storedAccentColor
            }
            defaultPile.useFullTint = storedUseFullTint
            defaultPile.meshOpacityScale = storedMeshOpacityScale
            defaultPile.rainbowRave = storedRainbowRave
            context.insert(defaultPile)
            try? context.save()
            activePile = defaultPile
            activePileIDString = defaultPile.name
            return
        }

        // Restore by stored name
        if let stored = piles.first(where: { $0.name == activePileIDString }) {
            activePile = stored
        } else if let defaultPile = piles.first(where: { $0.isDefault }) {
            activePile = defaultPile
        } else {
            activePile = piles.first
        }

        // Sync the restored pile's theme into AppStorage so MeshGradientBackground
        // and other @AppStorage readers reflect the correct pile immediately.
        syncAppStorage()
    }

    func switchTo(_ pile: Pile) {
        activePile = pile
        activePileIDString = pile.name
        syncAppStorage()
    }

    /// Writes the active pile's theme values into the shared AppStorage keys
    /// that MeshGradientBackground and other views read directly.
    func syncAppStorage() {
        guard let pile = activePile else { return }
        storedAccentColor = pile.accentColorRaw
        storedUseFullTint = pile.useFullTint
        storedMeshOpacityScale = pile.meshOpacityScale
        storedRainbowRave = pile.rainbowRave
    }

    /// Creates a new pile, inserts it, and optionally switches to it.
    @discardableResult
    func createPile(named name: String, context: ModelContext, switchToNew: Bool = false) -> Pile {
        let pile = Pile(name: name)
        context.insert(pile)
        try? context.save()
        if switchToNew {
            switchTo(pile)
        }
        return pile
    }

    /// Deletes a pile (cascade deletes its canvases + clouds).
    /// If the deleted pile was active, switches to the default or first remaining pile.
    func deletePile(_ pile: Pile, from piles: [Pile], context: ModelContext) {
        let wasActive = activePile == pile
        context.delete(pile)
        try? context.save()

        if wasActive {
            let remaining = piles.filter { $0 !== pile }
            if let def = remaining.first(where: { $0.isDefault }) {
                switchTo(def)
            } else if let first = remaining.first {
                switchTo(first)
            } else {
                activePile = nil
            }
        }
    }
}
