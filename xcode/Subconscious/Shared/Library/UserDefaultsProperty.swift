//
//  UserDefaultsProperty.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/7/23.
//
import Combine
import Foundation

/// Creates a type-safe getter and setter for a UserDefaults key.
/// Properties decorated with `@UserDefaultsProperty` will get and set their
/// value from UserDefaults.
///
/// The property's default value will be used if no value is found in the
/// UserDefaults for that key.
///
/// You can subscribe to changes in this default via the projected value, using
/// `$name`, where name is the name of your property. Projected value is a
/// publisher that emits any time the wrapped value changes.
@propertyWrapper struct UserDefaultsProperty<Value: Equatable> {
    /// UserDefaults key
    let key: String
    /// Default value for key if not found in UserDefaults.
    let `default`: Value
    var scope = UserDefaults.standard
    private var subject: CurrentValueSubject<Value, Never>

    init(
        wrappedValue: Value,
        forKey key: String,
        scope: UserDefaults = .standard
    ) {
        self.key = key
        self.default = wrappedValue
        self.subject = CurrentValueSubject(wrappedValue)
    }
    
    // Projected value is accessable via the `$` notation.
    var projectedValue: AnyPublisher<Value, Never> {
        // removeDuplicates prevents us from firing a send for changes that
        // did not actually update the equatable value.
        self.subject.removeDuplicates().eraseToAnyPublisher()
    }

    var wrappedValue: Value {
        get {
            scope.value(forKey: key) as? Value ?? `default`
        }
        nonmutating set {
            scope.set(newValue, forKey: key)
            self.subject.send(newValue)
        }
    }
}
