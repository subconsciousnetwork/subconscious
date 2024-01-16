//
//  ActivityEvent.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 10/1/2024.
//

import Foundation

struct ActivityEvent<Metadata: Codable>: Codable {
    let category: ActivityEventCategory
    let event: String
    let message: String
    let metadata: Metadata?
}

enum ActivityEventCategory: String, Codable {
    case system = "system"
    case deck = "deck"
    case note = "note"
    case addressBook = "addressBook"
}
