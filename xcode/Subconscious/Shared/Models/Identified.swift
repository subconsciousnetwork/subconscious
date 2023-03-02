//
//  Identified.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/2/23.
//

import Foundation

/// A wrapping type that is identifiable.
/// Use to wrap types that can't conform to identifiable.
struct Identified<Value>: Identifiable, Equatable
where Value: Equatable
{
    var id = UUID()
    var value: Value
}
