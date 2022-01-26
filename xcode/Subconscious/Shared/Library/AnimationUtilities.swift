//
//  AnimationUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/25/22.
//

import SwiftUI

/// A namespace for holding common animation duration constants
enum Duration {}

extension Duration {
    static let fast: Double = 0.18
    // iOS default
    static let normal: Double = 0.2
}

extension Animation {
    //  Penner curves sourced from
    //  https://matthewlein.com/tools/ceaser

    /// Penner easeOutCubic curve
    static func easeOutCubic(duration: Double = Duration.normal) -> Animation {
        .timingCurve(
            0.215,
            0.610,
            0.355,
            1,
            duration: duration
        )
    }
}
