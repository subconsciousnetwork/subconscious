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
    var debug = false

    /// Standard interval at which to run long-polling services
    var pollingInterval: Double = 15

    /// Subsurface "orb" shader on main FAB
    var orbShaderEnabled = true

    /// Toggle journal suggestion feature
    var journalSuggestionEnabled = true
    /// Where to look for journal template
    var journalTemplate: Slug = Slug("special/template/journal")!

    /// Toggle scratch note suggestion feature
    var scratchSuggestionEnabled = false

    /// Toggle random suggestion feature
    var randomSuggestionEnabled = true

    /// Default links feature enabled?
    var linksEnabled = true
    /// Where to look for user-defined links
    var linksTemplate: Slug = Slug("special/links")!
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

extension Config {
    static func from(data: ConfigData?) -> Config {
        var config = Config()
        guard let data = data else {
            return config
        }
        if let debug = data.debug {
            config.debug = debug
        }
        if let journalSuggestionEnabled = data.journalSuggestionEnabled {
            config.journalSuggestionEnabled = journalSuggestionEnabled
        }
        if let scratchSuggestionEnabled = data.scratchSuggestionEnabled {
            config.scratchSuggestionEnabled = scratchSuggestionEnabled
        }
        if let randomSuggestionEnabled = data.randomSuggestionEnabled {
            config.randomSuggestionEnabled = randomSuggestionEnabled
        }
        if let linksEnabled = data.linksEnabled {
            config.linksEnabled = linksEnabled
        }
        if let linksFallback = data.linksFallback {
            config.linksFallback = linksFallback
        }
        return config
    }
}

/// A struct representing partial configuration data loaded from JSON
struct ConfigData: Codable {
    /// Load from JSON file
    static func load(_ url: URL) throws -> ConfigData {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let json = try decoder.decode(ConfigData.self, from: data)
        return json
    }

    var debug: Bool?

    /// Toggle journal suggestion feature
    var journalSuggestionEnabled: Bool?
    /// Where to look for journal template
    var journalTemplate: Slug?

    /// Toggle scratch note suggestion feature
    var scratchSuggestionEnabled: Bool?

    /// Toggle random suggestion feature
    var randomSuggestionEnabled: Bool?

    /// Default links feature enabled?
    var linksEnabled: Bool?
    /// Template for default links
    var linksFallback: [Slug]?
}
