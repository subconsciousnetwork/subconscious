//
//  AngleUtilities.swift
//  Subconscious
//
//  Created by Ben Follington on 20/3/2024.
//

import SwiftUI

extension Angle {
    static func percent(_ percent: Double) -> Angle {
        Angle(degrees: percent * 360)
    }
}
