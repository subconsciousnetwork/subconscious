//
//  Audience.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/16/23.
//

import Foundation

/// Model enumerating the possible audience/scopes for a piece of content.
/// Right now we only have two: local-only draft or fully public
enum Audience: String, Codable, CustomStringConvertible {
    /// A local-only draft
    case local = "local"
    /// Public sphere content
    case `public` = "public"
    
    /// The user-facing description of this value.
    /// For users, we index on the value proposition, not the implementation
    /// detail of where the note is stored.
    ///
    /// - `.local` is draft
    /// - `.public` is public
    var userDescription: String {
        switch self {
        case .local:
            return String(localized: "Draft")
        case .public:
            return String(localized: "Public")
        }
    }
}

extension Audience: LosslessStringConvertible {
    var description: String {
        self.rawValue
    }
    
    init?(_ description: String) {
        self.init(rawValue: description)
    }
}

extension String {
    func toAudience() -> Audience? {
        Audience(rawValue: self)
    }
}

