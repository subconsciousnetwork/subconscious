//
//  Config.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/19/22.
//

import Foundation

/// Feature flags and settings
struct Config: Equatable, Codable {
    /// App version.
    var rdns = "com.subconscious.Subconscious"
    var debug = false
    
    var noosphere = NoosphereConfig()
    
    var appTabs = false
    var addByQRCode = true
    var userProfile = true
    
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
    
    var subconsciousGeistDid: Did = Did(
        Bundle.main.object(forInfoDictionaryKey: "DEFAULT_GEIST_DID") as! String
    )!
    var subconsciousGeistPetname: Petname = Petname(
        Bundle.main.object(forInfoDictionaryKey: "DEFAULT_GEIST_PETNAME") as! String
    )!
    
    /// URL for sending feedback to developers
    var feedbackURL: URL = URL(string: Bundle.main.object(forInfoDictionaryKey: "FEEDBACK_URL") as! String)!
    
    /// URL for built-in web service
    var cloudCtlUrl: URL = URL(string: Bundle.main.object(forInfoDictionaryKey: "CLOUDCTL_URL") as! String)!
    
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
    /// Hard-coded version number for Noosphere.
    /// NOTE: be sure to update this when we update Noosphere.
    /// We include this here so we can display it in settings.
    /// In future, Noosphere may expose an FFI to dynamically query for the
    /// version.
    var version = "v0.12.1"
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
