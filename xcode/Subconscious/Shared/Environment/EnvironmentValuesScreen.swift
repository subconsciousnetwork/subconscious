//
//  Screen.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/26/22.
//

import SwiftUI

extension EnvironmentValues {
    var screenBounds: CGRect {
        get {
            UIScreen.main.bounds
        }
    }
}
