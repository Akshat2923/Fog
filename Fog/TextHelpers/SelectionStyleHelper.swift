//
//  SelectionStyleHelper.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/22/26.
//

import Foundation
import SwiftUI

enum SelectionState {
    enum ToggleState {
        case on, off
    }
    /// Collects the attribute containers for all runs intersecting the current selection.
    static func selectedAttributeContainers(
        text: AttributedString,
        selection: inout AttributedTextSelection
    ) -> [AttributeContainer] {
        var containers: [AttributeContainer] = []
        var probe = text
        probe.transformAttributes(in: &selection) { container in
            containers.append(container)
        }
        return containers
    }
    
    /// Computes toggle states for the specified text attributes across the current selection,
    /// using a caller-provided resolver for all specified traits.
    static func selectionStyleState(
        text: AttributedString,
        selection: inout AttributedTextSelection,
        resolveTraits: (Font) -> (isBold: Bool, isItalic: Bool)
    ) -> (
        bold: ToggleState,
        italic: ToggleState,
        underline: ToggleState,
        strikethrough: ToggleState,
        leftAlignment: ToggleState,
        centerAlignment: ToggleState,
        rightAlignment: ToggleState,
        extraLargeFont: ToggleState,
        largeFont: ToggleState,
        mediumFont: ToggleState,
        bodyFont: ToggleState,
        footnoteFont: ToggleState
    ) {
        let containers = selectedAttributeContainers(text: text, selection: &selection)
        
        guard !containers.isEmpty else {
            return (.off, .off, .off, .off, .off, .off, .off, .off, .off, .off, .off, .off)
        }

        var allBold = true, allItalic = true, allUnderline = true, allStrike = true
        var allLeft = true, allCenter = true, allRight = true
        var allExtraLarge = true, allLarge = true, allMedium = true, allBody = true, allFootnote = true

        for container in containers {
            let traits = resolveTraits(container.font ?? .default)
            if !traits.isBold { allBold = false }
            if !traits.isItalic { allItalic = false }
            if container.underlineStyle != .single { allUnderline = false }
            if container.strikethroughStyle != .single { allStrike = false }
            if container.alignment != .left { allLeft = false }
            if container.alignment != .center { allCenter = false }
            if container.alignment != .right { allRight = false }
            if container.font != .title { allExtraLarge = false }
            if container.font != .title2 { allLarge = false }
            if container.font != .title3 { allMedium = false }
            if container.font != .body { allBody = false }
            if container.font != .footnote { allFootnote = false }
        }

        return (
            bold: allBold ? .on : .off,
            italic: allItalic ? .on : .off,
            underline: allUnderline ? .on : .off,
            strikethrough: allStrike ? .on : .off,
            leftAlignment: allLeft ? .on : .off,
            centerAlignment: allCenter ? .on : .off,
            rightAlignment: allRight ? .on : .off,
            extraLargeFont: allExtraLarge ? .on : .off,
            largeFont: allLarge ? .on : .off,
            mediumFont: allMedium ? .on : .off,
            bodyFont: allBody ? .on : .off,
            footnoteFont: allFootnote ? .on : .off
        )
    }
    
    static func isSelected(for state: ToggleState) -> Bool {
        return state == .on
    }
}

