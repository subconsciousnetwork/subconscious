//
//  Audience.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/16/23.
//

import Foundation

/// Model enumerating the possible audience/scopes for a piece of content.
/// Right now we only have two: local-only draft or fully public
enum Audience: Int, Codable, CustomStringConvertible {
    /// A local-only draft
    case local = 0
    /// Public sphere content
    case `public` = 1
}

extension Audience {
    var description: String {
        switch self {
        case .local:
            return "Local"
        case .public:
            return "Everyone"
        }
    }
    
    
}

extension Int {
    func toAudience() -> Audience? {
        Audience(rawValue: self)
    }
}
