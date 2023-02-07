//
//  UserDefaultsProperty.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/7/23.
//

import Foundation

protocol UserDefaultsPropertyProtocol {}

extension Data: UserDefaultsPropertyProtocol {}
extension String: UserDefaultsPropertyProtocol {}
extension Date: UserDefaultsPropertyProtocol {}
extension Bool: UserDefaultsPropertyProtocol {}
extension Int: UserDefaultsPropertyProtocol {}
extension Double: UserDefaultsPropertyProtocol {}
extension Float: UserDefaultsPropertyProtocol {}

/// Create a type-safe getter/setter for a UserDefaults key.
struct UserDefaultsProperty<Value: UserDefaultsPropertyProtocol> {
    /// The user defaults bucket to use
    private let domain: UserDefaults
    private let `default`: Value
    /// User defaults key, a string enum
    let key: String
    
    init(
        key: String,
        default: Value,
        domain: UserDefaults = UserDefaults.standard
    ) {
        self.key = key
        self.`default` = `default`
        self.domain = domain
    }

    func get() -> Value {
        domain.value(forKey: key) as? Value ?? `default`
    }
    
    func set(_ value: Value) {
        domain.set(value, forKey: key)
    }
}

/// Create a type-safe getter/setter for a UserDefaults key that may be nil
struct OptionalUserDefaultsProperty<Value: UserDefaultsPropertyProtocol> {
    /// The user defaults bucket to use
    private let domain: UserDefaults
    private let type: Value.Type
    /// User defaults key, a string enum
    let key: String
    
    init(
        key: String,
        type: Value.Type,
        domain: UserDefaults = UserDefaults.standard
    ) {
        self.key = key
        self.type = type
        self.domain = domain
    }

    func get() -> Value? {
        domain.value(forKey: key) as? Value
    }
    
    func set(_ value: Value?) {
        domain.set(value, forKey: key)
    }
}
