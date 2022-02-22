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

    /// Standard interval at which to run long-polling services
    var pollingInterval: Double = 15

    /// Subsurface "orb" shader on main FAB
    var orbShaderEnabled = false

    /// Toggle journal suggestion feature
    var journalSuggestionEnabled = true
    /// Where to look for journal template
    var journalTemplate: Slug = Slug("special/template/journal")!

    /// Toggle scratch note suggestion feature
    var scratchSuggestionEnabled = true

    /// Toggle random suggestion feature
    var randomSuggestionEnabled = true
}
