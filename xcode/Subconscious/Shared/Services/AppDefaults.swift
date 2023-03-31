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

    @UserDefaultsProperty(forKey: "ownerKeyName")
    var ownerKeyName: String? = nil
    
    /// The user/sphere nickname.
    @UserDefaultsProperty(forKey: "nickname")
    var nickname: String? = nil
    
    @UserDefaultsProperty(forKey: "sphereIdentity")
    var sphereIdentity: String? = nil
    
    @UserDefaultsProperty(forKey: "firstRunComplete")
    var firstRunComplete = false
    
    @UserDefaultsProperty(forKey: "gatewayURL")
    var gatewayURL = "http://127.0.0.1:4433"
}
