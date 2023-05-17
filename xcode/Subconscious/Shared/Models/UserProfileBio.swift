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
    Identifiable,
    Codable {
    
    public static let empty = UserProfileBio("")
    private static let visibleContentRegex = /[^\s]/
    
    public let verbatim: String
    public var id: String { verbatim }
    
    public var hasVisibleContent: Bool {
        verbatim.contains(Self.visibleContentRegex)
    }

    public init(_ description: String) {
        self.verbatim = description
            // Turn all whitespace into spaces
            .replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
            // Catch leading spaces
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(280)
            .toString()
    }
}
