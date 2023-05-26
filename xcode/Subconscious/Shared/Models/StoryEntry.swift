//
//  StoryEntry.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import Foundation

/// A story representing a single entry by a user
struct StoryEntry:
    Hashable,
    Identifiable,
    CustomStringConvertible,
    Codable
{
    var id = UUID()
    var author: UserProfile
    var entry: EntryStub

    var description: String {
        """
        \(author.displayName.markup)
        \(String(describing: entry))
        """
    }
}
