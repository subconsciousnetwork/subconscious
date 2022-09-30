//
//  Story.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/24/22.
//

import Foundation

/// Enum of possible story types for feed
enum Story: Hashable, Identifiable {
    case prompt(StoryPrompt)
    case combo(StoryCombo)
    case onThisDay(StoryOnThisDay)

    var id: UUID {
        switch self {
        case .prompt(let prompt):
            return prompt.id
        case .combo(let combo):
            return combo.id
        case .onThisDay(let onThisDay):
            return onThisDay.id
        }
    }
}
