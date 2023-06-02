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
    
    /// Are Noosphere features enabled for end-users?
    @UserDefaultsProperty(forKey: "isNoosphereEnabled")
    var isNoosphereEnabled = false
    
    @UserDefaultsProperty(forKey: "sphereIdentity")
    var sphereIdentity: String? = nil
    
    @UserDefaultsProperty(forKey: "firstRunComplete")
    var firstRunComplete = false
    
    @UserDefaultsProperty(forKey: "gatewayURL")
    var gatewayURL = "http://127.0.0.1:4433"
    
    @UserDefaultsProperty(forKey: "gatewayId")
    var gatewayId: String? = nil
    
    @UserDefaultsProperty(forKey: "inviteCode")
    var inviteCode: String? = nil
}
