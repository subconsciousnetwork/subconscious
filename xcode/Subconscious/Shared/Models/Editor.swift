//
//  Editor.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/27/22.
//

import Foundation

/// Holds the state for an editor
struct Editor: Hashable {
    /// Current slug editor is set to, if any
    var slug: Slug?

    /// Is editor saved?
    var saveState = SaveState.saved

    /// Is editor in loading state?
    var isLoading = true

    /// Text of editor
    var text: String = ""

    /// Current user text selection
    var selection = NSMakeRange(0, 0)

    /// The entry link within the text
    var selectedEntryLinkMarkup: Subtext.EntryLinkMarkup?
}
