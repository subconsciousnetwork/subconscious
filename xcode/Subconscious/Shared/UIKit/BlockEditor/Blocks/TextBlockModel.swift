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
        /// The selection/text cursor position
        var selection: NSRange = NSMakeRange(0, 0)
        /// Is the text editor focused?
        var isFocused = false
        /// Is this block in multi-block select mode?
        var isBlockSelectMode = false
        var isBlockSelected = false
        var transcludes: [EntryStub] = []
        
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
