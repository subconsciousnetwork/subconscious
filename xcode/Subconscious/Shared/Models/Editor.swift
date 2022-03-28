//
//  Editor.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/23/22.
//
import Foundation

struct Editor: Equatable {
    var text = ""
    /// Are all changes to editor saved?
    var saveState = SaveState.saved
    /// Editor selection corresponds with `editorAttributedText`
    var selection = NSMakeRange(0, 0)
    /// Slashlink currently being written (if any)
    var selectedSlashlink: Subtext.Slashlink? = nil
}
