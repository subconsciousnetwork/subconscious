//
//  Config.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/19/22.
//

import Foundation

/// Feature flags and settings
struct Config: Equatable {
    let rdns = "com.subconscious.Subconscious"
    var debug = false

    var appTabs = true

    /// Standard interval at which to run long-polling services
    var pollingInterval: Double = 15

    /// Subsurface "orb" shader on main FAB
    var orbShaderEnabled = true

    /// Toggle scratch note suggestion feature
    var scratchSuggestionEnabled = true
    var scratchDefaultTitle = "Untitled"

    /// Toggle random suggestion feature
    var randomSuggestionEnabled = true

    /// Default links feature enabled?
    var linksEnabled = true
    /// Where to look for user-defined links
    var linksTemplate: Slug = Slug("_special/links")!
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

    /// Toggle on/off simple Tracery-based Geists
    var traceryZettelkasten = "zettelkasten"
    var traceryCombo = "combo"
    var traceryProject = "project"
}

extension Config {
    static let `default` = Config()
}
