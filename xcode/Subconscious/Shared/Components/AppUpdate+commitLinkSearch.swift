//
//  AppUpdate+commitLinkSearch.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func commitLinkSearch(state: AppModel, text: String) -> Change<AppModel, AppAction> {
        var model = state
        if let range = Range(
            model.editorSelection,
            in: state.editorAttributedText.string
        ) {
            // Replace selected range with committed link search text.
            let markup = state.editorAttributedText.string
                .replacingCharacters(
                    in: range,
                    with: text
                )
            // Re-render and assign
            model.editorAttributedText = renderMarkup(markup: markup)
            // Find inserted range by searching for our inserted text
            // AFTER the cursor position.
            if let insertedRange = markup.range(
                of: text,
                range: range.lowerBound..<markup.endIndex
            ) {
                // Convert Range to NSRange of editorAttributedText,
                // assign to editorSelection.
                model.editorSelection = NSRange(
                    insertedRange,
                    in: markup
                )
            }
        }
        model.linkSearchQuery = text
        model.linkSearchText = ""
        model.focus = nil
        model.isLinkSheetPresented = false
        return Change(state: model)
    }
}
