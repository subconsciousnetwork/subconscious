//
//  SubtextMarkup.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/26/23.
//

import Foundation

enum SubtextEditorMarkup {}

extension SubtextEditorMarkup {
    struct Replacement {
        var string: String
        var replacement: Range<String.Index>
        var tagOpen: Range<String.Index>
        var tagClose: Range<String.Index>
        var tagContent: Range<String.Index>
        
        init(
            string: String,
            replacement: Range<String.Index>,
            tagOpen: Range<String.Index>,
            tagClose: Range<String.Index>,
            tagContent: Range<String.Index>
        ) {
            self.string = string
            self.replacement = replacement
            self.tagOpen = tagOpen
            self.tagClose = tagClose
            self.tagContent = tagContent
        }
    }
    
    static func wrapMarkup(
        _ text: String,
        selection: Range<String.Index>,
        openingTag: String,
        closingTag: String
    ) -> Replacement? {
        let selection = selection.clamped(to: text.startIndex..<text.endIndex)
        let wrappedText = text[selection]
        let formattedText = "\(openingTag)\(wrappedText)\(closingTag)"
        
        var text = text
        text.replaceSubrange(selection, with: formattedText)
        
        let tagOpenStartIndex = selection.lowerBound
        guard let tagOpenEndIndex = text.index(
            tagOpenStartIndex,
            offsetBy: openingTag.count,
            limitedBy: text.endIndex
        ) else {
            return nil
        }
        
        let tagContentStartIndex = tagOpenEndIndex
        guard let tagContentEndIndex = text.index(
            tagContentStartIndex,
            offsetBy: wrappedText.count,
            limitedBy: text.endIndex
        ) else {
            return nil
        }
        
        let tagCloseStartIndex = tagContentEndIndex
        guard let tagCloseEndIndex = text.index(
            tagCloseStartIndex,
            offsetBy: closingTag.count,
            limitedBy: text.endIndex
        ) else {
            return nil
        }
        
        return Replacement(
            string: text,
            replacement: tagOpenStartIndex..<tagCloseEndIndex,
            tagOpen: tagOpenStartIndex..<tagOpenEndIndex,
            tagClose: tagCloseStartIndex..<tagCloseEndIndex,
            tagContent: tagContentStartIndex..<tagContentEndIndex
        )
    }
    
    static func wrapBold(
        _ text: String,
        selection: Range<String.Index>
    ) -> Replacement? {
        wrapMarkup(
            text,
            selection: selection,
            openingTag: "*",
            closingTag: "*"
        )
    }
    
    static func wrapItalic(
        _ text: String,
        selection: Range<String.Index>
    ) -> Replacement? {
        wrapMarkup(
            text,
            selection: selection,
            openingTag: "_",
            closingTag: "_"
        )
    }
    
    static func wrapCode(
        _ text: String,
        selection: Range<String.Index>
    ) -> Replacement? {
        wrapMarkup(
            text,
            selection: selection,
            openingTag: "`",
            closingTag: "`"
        )
    }
}
