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
    Codable
{
    private static let recoveryPhraseRegex = /^(?:\w+\s+){23}\w+$/

    @Redacted public private(set) var secret: String

    public init?(_ description: String) {
        guard description.wholeMatch(of: Self.recoveryPhraseRegex) != nil else {
            return nil
        }
        self.secret = description.lowercased()
    }
}
