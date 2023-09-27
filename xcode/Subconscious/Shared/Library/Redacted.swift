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
public struct Redacted<Value>:
    CustomStringConvertible,
    CustomDebugStringConvertible
{
    public var wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public var description: String {
        return "--redacted--"
    }
    
    public var debugDescription: String {
        return "--redacted--"
    }
}

extension Redacted: Equatable where Value: Equatable {}
extension Redacted: Hashable where Value: Hashable {}
extension Redacted: Codable where Value: Codable {}
