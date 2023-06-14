//
//  UserProfileBio.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 17/5/2023.
//

import Foundation

/// A type representing a user profile bio, with restricted characters and length.
public struct UserProfileBio:
    Hashable,
    Equatable,
    Codable {
    
    public static let empty = UserProfileBio("")
    public static let maxLength = 280
    
    public let text: String
    
    public var hasVisibleContent: Bool {
        text.hasVisibleContent
    }

    public init?(_ description: String) {
        self.text = description
            // Turn all whitespace into spaces
            .replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
            // Catch leading spaces
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(Self.maxLength)
            .toString()
        
        guard self.text.count <= Self.maxLength else {
            return nil
        }
    }
}
