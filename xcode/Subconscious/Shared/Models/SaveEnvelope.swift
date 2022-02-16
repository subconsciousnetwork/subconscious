//
//  SaveEnvelope.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/16/22.
//

import Foundation

/// Envelope denoting the save state of a resource
struct SaveEnvelope<T>: Equatable
where T: Equatable {
    var state: SaveState
    var value: T
}
