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
    CustomStringConvertible
{
    var id = UUID()
    var entry: EntryStub
    var author: UserProfile

    var description: String {
        """
        \(String(describing: author.address))
        \(String(describing: entry))
        """
    }
}
