//
//  UserDefaultsService.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/7/23.
//

import Foundation

/// Exposes getters/setters for user defaults keys that we use.
struct AppDefaultsService {
    var nickname = OptionalUserDefaultsProperty(
        key: "nickname",
        type: String.self
    )
    
    var sphereIdentity = OptionalUserDefaultsProperty(
        key: "sphereIdentity",
        type: String.self
    )
    
    var firstRunComplete = UserDefaultsProperty(
        key: "firstRunComplete",
        default: false
    )
    
    var noosphereEnabled = UserDefaultsProperty(
        key: "noosphereEnabled",
        default: false
    )
    
    var defaultGatewayURL = UserDefaultsProperty(
        key: "defaultGatewayURL",
        default: "http://127.0.0.1:4433"
    )
}
