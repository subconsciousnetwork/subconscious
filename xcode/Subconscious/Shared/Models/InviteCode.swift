//
//  InviteCode.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 3/5/2023.
//

import Foundation

/// A type representing a valid petname (`@petname`)
public struct InviteCode:
    Hashable,
    Equatable,
    Identifiable,
    Comparable,
    Codable,
    LosslessStringConvertible
{
    private static let inviteCodeRegex = /^\w+\s\w+\s\w+\s\w+$/
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.id < rhs.id
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public let description: String
    public let verbatim: String
    public var id: String { description }
    
    public var markup: String {
        "@\(self.description)"
    }
    
    public var verbatimMarkup: String {
        "@\(self.verbatim)"
    }

    public init?(_ description: String) {
        guard description.wholeMatch(of: Self.inviteCodeRegex) != nil else {
            return nil
        }
        self.description = description.lowercased()
        self.verbatim = description
    }
}
