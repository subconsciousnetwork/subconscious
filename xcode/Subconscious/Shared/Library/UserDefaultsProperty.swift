//
//  UserDefaultsProperty.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/7/23.
//

import Foundation

@propertyWrapper
struct UserDefaultsProperty<Value> {
    let key: String
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
