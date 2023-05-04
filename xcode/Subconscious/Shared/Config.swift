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
    var addByQRCode = true
    var userProfile: Bool {
        AppDefaults.standard.isNoosphereEnabled
    }
    
    #if targetEnvironment(simulator)
    /// Are we currently running in the iOS simlator (aka dev mode)
    private static let isSimulator = true
    #else
    /// Are we currently running in the iOS simlator (aka dev mode)
    private static let isSimulator = false
    #endif
    
    /// What value should the DID QR code scanner return in the simulator?
    /// Only returns test data when Config.debug is enabled
    var fallbackSimulatorQrCodeScanResult: String {
        Self.isSimulator
            ? "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
            : ""
    }
    var subconsciousGeistDid: Did = Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!
    var subconsciousGeistPetname: Petname = Petname("subconscious")!
    
    var cloudCtlUrl: URL = URL(string: "https://cloudctl.sphere.test.subconscious.cloud")!

    /// Standard interval at which to run long-polling services
    var pollingInterval: Double = 15

    var untitled = "Untitled"

    /// Toggle random suggestion feature
    var randomSuggestionEnabled = true

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
    /// Owner key name for key that owns default sphere on this device.
    var ownerKeyName = "Subconscious"
    var defaultGatewayURL = "http://127.0.0.1:4433"
}
