//
//  AppUpdate+resetEditor.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    /// Set all editor properties to initial values
    static func resetEditor(_ model: inout AppModel) {
        model.editorAttributedText = NSAttributedString("")
        model.editorSelection = NSMakeRange(0, 0)
        model.focus = nil
    }
}
