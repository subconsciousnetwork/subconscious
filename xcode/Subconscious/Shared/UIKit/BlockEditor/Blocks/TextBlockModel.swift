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
        var dom = Subtext.empty
        /// The selection/text cursor position
        var selection: NSRange = NSMakeRange(0, 0)
        /// Is the text editor focused?
        var isEditing = false
        /// Is select mode enabled in the editor?
        /// Our collection view is data-driven, so we set this flag for every
        /// block.
        var isBlockSelectMode = false
        /// Is this particular block selected?
        var isBlockSelected = false
        var transcludes: [EntryStub] = []
        
        /// Set text, updating selection
        func setText(
            dom: Subtext,
            selection: NSRange
        ) -> Self {
            var this = self
            this.dom = dom
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
