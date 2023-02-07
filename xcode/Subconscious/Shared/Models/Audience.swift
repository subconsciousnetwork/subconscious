//
//  Audience.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/16/23.
//

import Foundation

/// Model enumerating the possible audience/scopes for a piece of content.
/// Right now we only have two: local-only draft or fully public
enum Audience: Int, Codable {
    /// A local-only draft
    case local = 0
    /// Public sphere content
    case `public` = 1
}

extension Int {
    func toAudience() -> Audience? {
        Audience(rawValue: self)
    }
}
