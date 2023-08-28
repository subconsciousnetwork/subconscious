//
//  TextBlockModel.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/17/23.
//

import Foundation

extension BlockEditor {
    struct TextBlockModel: Hashable, Identifiable {
        var id = UUID()
        var text = ""
        var selection: NSRange = NSMakeRange(0, 0)
        var isFocused = false
        
        /// Set text, updating selection
        func setText(
            text: String,
            selection: NSRange
        ) -> Self {
            var this = self
            this.text = text
            this.selection = selection
            return this
        }
        
        /// Set text, updating selection
        func setSelection(
            selection: NSRange
        ) -> Self {
            var this = self
            this.selection = selection
            return this
        }
    }
}
