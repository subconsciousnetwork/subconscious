//
//  StoryCombo.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 24/9/2022.
//

import Foundation

/// Story prompt model
struct StoryCombo: Hashable, Identifiable, CustomStringConvertible {
    var id = UUID()
    var entryA: EntryStub
    var entryB: EntryStub

    var description: String {
        """
        \(entryA)
        +
        \(entryB)
        """
    }
}
