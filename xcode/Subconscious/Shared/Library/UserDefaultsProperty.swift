//
//  UserDefaultsProperty.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/7/23.
//
import Combine
import Foundation

/// Property wrapper that creates a type-safe getter/setter for a
/// UserDefaults key.
///
/// Properties decorated with `@UserDefaultsProperty` will get and set their
/// value from UserDefaults. The property's default value will be used if
/// no value is found in the UserDefaults for that key.
///
/// You can subscribe to changes in this default via the projected value, using
/// `$name`, where name is the name of your property. Projected value is a
/// publisher that emits any time the wrapped value changes.
@propertyWrapper struct UserDefaultsProperty<Value: Equatable> {
    /// Create a type-safe accessor for a UserDefaults key.
    private struct UserDefaultsKey {
        var key: String
        var `default`: Value
        var scope = UserDefaults.standard
        
        var value: Value {
            get {
                scope.value(forKey: key) as? Value ?? `default`
            }
            nonmutating set {
                scope.set(newValue, forKey: key)
            }
        }
    }

    /// UserDefaults key
    let key: String
    private var store: UserDefaultsKey
    private var subject: CurrentValueSubject<Value, Never>

    init(
        wrappedValue: Value,
        forKey key: String,
        scope: UserDefaults = .standard
    ) {
        self.key = key
        self.store = UserDefaultsKey(
            key: key,
            default: wrappedValue,
            scope: scope
        )
        self.subject = CurrentValueSubject(store.value)
    }
    
    // Projected value is accessable via the `$` notation.
    var projectedValue: AnyPublisher<Value, Never> {
        // removeDuplicates prevents us from firing a send for changes that
        // did not actually update the equatable value.
        self.subject.removeDuplicates().eraseToAnyPublisher()
    }

    var wrappedValue: Value {
        get {
            store.value
        }
        nonmutating set {
            store.value = newValue
        }
    }
}
