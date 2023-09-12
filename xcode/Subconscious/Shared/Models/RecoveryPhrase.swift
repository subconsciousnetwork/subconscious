//
//  RecoveryPhrase.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 12/9/2023.
//

import Foundation

/// A type representing a valid recovery phrase (24 words)
public struct RecoveryPhrase:
    Hashable,
    Equatable,
    Identifiable,
    Codable,
    LosslessStringConvertible {
    
    private static let recoveryPhraseRegex = /^(?:\w+\s+){23}\w+$/

    public let description: String
    public let verbatim: String
    public var id: String { description }

    public init?(_ description: String) {
        guard description.wholeMatch(of: Self.recoveryPhraseRegex) != nil else {
            return nil
        }
        self.description = description.lowercased()
        self.verbatim = description
    }
}
