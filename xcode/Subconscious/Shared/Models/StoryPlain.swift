//
//  StoryPlain.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import Foundation

/// Story prompt model
struct StoryPlain:
    Hashable,
    Identifiable,
    CustomStringConvertible,
    Codable
{
    var id = UUID()
    var entry: EntryStub

    var description: String {
        """
        \(String(describing: entry))
        """
    }
}
