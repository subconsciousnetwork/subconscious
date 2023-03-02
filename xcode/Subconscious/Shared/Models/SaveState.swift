//
//  SaveState.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/10/22.
//

import Foundation

/// A simple enum representing saved state, including in-progress write.
enum SaveState: Hashable, Equatable {
    case unsaved
    case saving
    case saved
}
