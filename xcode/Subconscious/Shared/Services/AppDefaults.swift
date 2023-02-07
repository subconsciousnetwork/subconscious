//
//  UserDefaultsService.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/7/23.
//

import Foundation

/// Exposes getters/setters for user defaults keys that we use.
struct AppDefaults {
    static let nickname = OptionalUserDefaultsProperty(
        key: "nickname",
        type: String.self
    )
    
    static let sphereIdentity = OptionalUserDefaultsProperty(
        key: "sphereIdentity",
        type: String.self
    )
    
    static let firstRunComplete = UserDefaultsProperty(
        key: "firstRunComplete",
        default: false
    )
    
    static let noosphereEnabled = UserDefaultsProperty(
        key: "noosphereEnabled",
        default: false
    )
    
    static let gatewayURL = UserDefaultsProperty(
        key: "gatewayURL",
        default: "http://127.0.0.1:4433"
    )
}
