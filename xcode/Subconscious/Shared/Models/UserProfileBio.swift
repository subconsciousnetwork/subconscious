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
    
    public let bio: String
    public var id: String { bio }
    
    public var hasVisibleContent: Bool {
        bio.contains(Self.visibleContentRegex)
    }

    public init(_ description: String) {
        let bio = description.prefix(280)
        // Turn all whitespace into spaces
        let cleanedBio = bio.replacingOccurrences(
            of: "\\s",
            with: " ",
            options: .regularExpression
        )

        self.bio = cleanedBio
    }
}
