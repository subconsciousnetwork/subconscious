//
//  Editor2.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/28/22.
//

import Foundation

struct Editor2: Equatable {
    var slug: Slug
    var isLoading = false
    var text = ""
    /// Are all changes to editor saved?
    var saveState = SaveState.saved
    /// Editor selection corresponds with `editorAttributedText`
    var selection = NSMakeRange(0, 0)
    /// Slashlink currently being written (if any)
    var selectedSlashlink: Subtext.Slashlink? = nil
}
