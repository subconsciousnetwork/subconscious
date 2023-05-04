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
    Codable,
    LosslessStringConvertible {
    
    private static let inviteCodeRegex = /^\w+\s\w+\s\w+\s\w+$/

    public let description: String
    public let verbatim: String
    public var id: String { description }

    public init?(_ description: String) {
        guard description.wholeMatch(of: Self.inviteCodeRegex) != nil else {
            return nil
        }
        self.description = description.lowercased()
        self.verbatim = description
    }
}
