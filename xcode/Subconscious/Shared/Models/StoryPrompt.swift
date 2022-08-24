//
//  StoryPrompt.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/24/22.
//

import Foundation

/// Story prompt model
struct StoryPrompt: Hashable, Identifiable, CustomStringConvertible {
    var entry: EntryStub
    var prompt: String

    var description: String {
        """
        \(prompt)
        
        \(String(describing: entry))
        """
    }

    var id: String {
        "/story/prompt/\(entry.slug)"
    }
}
