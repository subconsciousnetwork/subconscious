//
//  UserDefaultsProperty.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/7/23.
//

import Foundation

/// Creates a type-safe getter and setter for a UserDefaults key.
/// Properties decorated with `@UserDefaultsProperty` will get and set their
/// value from UserDefaults.
///
/// The property's default value will be used if no value is found in the
/// UserDefaults for that key.
@propertyWrapper struct UserDefaultsProperty<Value> {
    /// UserDefaults key
    let key: String
    /// Default value for key if not found in UserDefaults.
    let `default`: Value
    var scope = UserDefaults.standard

    init(
        wrappedValue: Value,
        forKey key: String,
        scope: UserDefaults = .standard
    ) {
        self.key = key
        self.default = wrappedValue
    }
    
    var wrappedValue: Value {
        get {
            scope.value(forKey: key) as? Value ?? `default`
        }
        set {
            scope.set(newValue, forKey: key)
        }
    }
}
