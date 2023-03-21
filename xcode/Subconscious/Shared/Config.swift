//
//  Config.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/19/22.
//

import Foundation

/// Feature flags and settings
struct Config: Equatable, Codable {
    var rdns = "com.subconscious.Subconscious"
    var debug = false

    var noosphere = NoosphereConfig()

    var appTabs = false
    var addressBook = false
    var addByQrCode = false

    /// Standard interval at which to run long-polling services
    var pollingInterval: Double = 15

    var untitled = "Untitled"

    /// Toggle random suggestion feature
    var randomSuggestionEnabled = true

    var memoViewerDetailEnabled = false
    
    /// Toggle on/off simple Tracery-based Geists
    var traceryZettelkasten = "zettelkasten"
    var traceryCombo = "combo"
    var traceryProject = "project"
}

extension Config {
    static let `default` = Config()
}

// MARK: Noosphere configuration
struct NoosphereConfig: Equatable, Codable {
    /// Name of directory used for Noosphere storage
    var globalStoragePath = "noosphere"
    /// Name of directory used for sphere storage.
    /// NOTE: In future, we might support multiple spheres. If so, this
    /// flag will be deprecated in favor of multiple spheres
    var sphereStoragePath = "sphere"
    /// Default owner key name for spheres on this device
    var ownerKeyName = "User"
    var defaultGatewayURL = "http://127.0.0.1:4433"
}
