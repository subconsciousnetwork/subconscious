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
    let debug = false

    /// Standard interval at which to run long-polling services
    var pollingInterval: Double = 15

    /// Subsurface "orb" shader on main FAB
    var orbShaderEnabled = true

    /// Toggle journal suggestion feature
    var journalSuggestionEnabled = true
    /// Where to look for journal template
    var journalTemplate: Slug = Slug("_special/journal/template")!

    /// Toggle scratch note suggestion feature
    var scratchSuggestionEnabled = false

    /// Toggle random suggestion feature
    var randomSuggestionEnabled = true

    /// Default links feature enabled?
    var linksEnabled = true
    /// Where to look for user-defined links
    var linksTemplate: Slug = Slug("_special/links/template")!
    /// Template for default links
    var linksFallback: [Slug] = [
        Slug("pattern")!,
        Slug("project")!,
        Slug("question")!,
        Slug("quote")!,
        Slug("book")!,
        Slug("reference")!,
        Slug("decision")!,
        Slug("person")!
    ]
}
