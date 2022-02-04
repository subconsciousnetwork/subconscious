//
//  Suggestions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/22.
//

import Foundation

/// A collection of search suggestions of different types.
/// Typically returned from a query.
struct Suggestions {
    /// The literal query
    var literal: EntryLink?
    /// The top result
    var top: EntryLink?
    /// Existing entries
    var entries: [EntryLink] = []
    /// Search terms
    var searches: [EntryLink] = []
}
