//
//  Story.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/24/22.
//

import Foundation

/// Enum of possible story types for feed
enum Story: Hashable {
    case prompt(StoryPrompt)
}
