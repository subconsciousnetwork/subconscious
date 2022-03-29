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

    /// iOS default animation duration
    static let normal: Double = 0.2

    //  NOTE: this could change in future, but for now, a hard-coded value
    //  is good enough.
    //  2022-01-27 Gordon Brander
    /// Duration of keyboard animation, as measured in iOS 15.2
    static let keyboard: Double = 0.25
}

extension Animation {
    //  Penner Bezier curves sourced from
    //  https://matthewlein.com/tools/ceaser

    /// Penner easeOutQuad curve
    static func easeOutQuad(duration: Double = Duration.normal) -> Animation {
        .timingCurve(
            0.250,
            0.460,
            0.450,
            0.940,
            duration: duration
        )
    }

    /// Penner easeOutCubic curve
    static func easeOutCubic(duration: Double = Duration.normal) -> Animation {
        .timingCurve(
            0.215,
            0.610,
            0.355,
            1.000,
            duration: duration
        )
    }

    /// Penner easeOutQuart curve
    static func easeOutQuart(duration: Double = Duration.normal) -> Animation {
        .timingCurve(
            0.165,
            0.840,
            0.440,
            1.000,
            duration: duration
        )
    }
}
