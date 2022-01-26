//
//  AnimationUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/25/22.
//

import SwiftUI

extension Animation {
    //  Penner curves sourced from
    //  https://matthewlein.com/tools/ceaser

    /// Penner easeOutCubic curve
    static func easeOutCubic(duration: Double = 1) -> Animation {
        .timingCurve(
            0.215,
            0.610,
            0.355,
            1,
            duration: duration
        )
    }
}
