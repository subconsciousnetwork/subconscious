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
    
    //  NOTE: this could change in future, but for now, a hard-coded value
    //  is good enough.
    //  2023-03-07 Gordon Brander
    /// Approximate sheet animation duration.
    static let sheet: Double = 0.25
    
    static let loading: Double = 0.75
}

extension Animation {
    //  Penner curves sourced from
    //  https://matthewlein.com/tools/ceaser
    
    static let resetScroll = Animation.easeInOut(duration: Duration.normal)

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
