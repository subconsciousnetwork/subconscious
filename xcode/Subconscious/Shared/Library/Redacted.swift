//
//  Redacted.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/27/23.
//

import Foundation

// Wrap a property, redacting it from accidental string conversion.
// Useful for annotating properties of types that contain sensitive information
// and that may be converted to string.
@propertyWrapper
struct Redacted<Value>:
    CustomStringConvertible,
    CustomDebugStringConvertible
{
    var wrappedValue: Value
    
    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    var description: String {
        return "--redacted--"
    }
    
    var debugDescription: String {
        return "--redacted--"
    }
}
