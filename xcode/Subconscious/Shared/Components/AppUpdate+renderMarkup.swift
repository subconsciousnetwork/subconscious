//
//  AppUpdate+renderMarkup.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func renderMarkup(
        markup: String
    ) -> NSAttributedString {
        Subtext(markup: markup)
            .renderMarkup(url: Slashlink.slashlinkToURLString)
    }
}
