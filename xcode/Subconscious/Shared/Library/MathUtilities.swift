//
//  MathUtilities.swift
//  Subconscious
//
//  Created by Ben Follington on 16/11/2023.
//

import Foundation

extension Comparable {
    public static func clamp<T: Comparable>(x: T, min lower: T, max upper: T) -> T {
        return min(max(x, lower), upper)
    }
    
    public func clamp(min lower: Self, max upper: Self) -> Self {
        return min(max(self, lower), upper)
    }
}

