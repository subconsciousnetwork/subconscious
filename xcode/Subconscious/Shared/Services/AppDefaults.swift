//
//  UserDefaultsService.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/7/23.
//

import Foundation

/// Exposes getters/setters for UserDefaults-persisted keys that we use.
struct AppDefaults {
    static var standard = AppDefaults()
    
    @UserDefaultsProperty(forKey: "sphereIdentity")
    var sphereIdentity: String? = nil
    
    @UserDefaultsProperty(forKey: "firstRunComplete")
    var firstRunComplete = false
    
    static let defaultGatewayURL = "http://127.0.0.1:4433"
    @UserDefaultsProperty(forKey: "gatewayURL")
    var gatewayURL = Self.defaultGatewayURL
    
    @UserDefaultsProperty(forKey: "gatewayId")
    var gatewayId: String? = nil
    
    @UserDefaultsProperty(forKey: "inviteCode")
    var inviteCode: String? = nil
    
    @UserDefaultsProperty(forKey: "blockEditor")
    var isBlockEditorEnabled: Bool = false
    
    @UserDefaultsProperty(forKey: "aiFeatures")
    var areAiFeaturesEnabled: Bool = false
    
    @UserDefaultsProperty(forKey: "preferredLlm")
    var preferredLlm: String = "gpt-4"

    @UserDefaultsProperty(forKey: "modalEditor")
    var isModalEditorEnabled: Bool = false
    
    @UserDefaultsProperty(forKey: "selectedAppTab")
    // default to the notebook on first run because there will be nothing in the feed
    // enums must be serialized when stored as AppDefaults:
    // https://cocoacasts.com/ud-6-how-to-store-an-enum-in-user-defaults-in-swift
    var selectedAppTab: String = AppTab.notebook.rawValue
    
    @UserDefaultsProperty(forKey: "noosphereLogLevel")
    var noosphereLogLevel: String = Noosphere.NoosphereLogLevel.basic.description
}
