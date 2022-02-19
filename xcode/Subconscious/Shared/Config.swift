//
//  Config.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/19/22.
//

import Foundation

/// Feature flags and settings
struct Config: Equatable {
    static let rdns = "com.subconscious.Subconscious"
    static let debug = false

    // Standard interval at which to run long-polling services
    var pollingInterval: Double = 15

    // Journal features
    var journalSuggestionEnabled = true
    var journalTemplate: Slug = Slug("special/template/journal")!

    // Scratch features
    var scratchSuggestionEnabled = true

    // Random suggestion
    var randomSuggestionEnabled = true
}
