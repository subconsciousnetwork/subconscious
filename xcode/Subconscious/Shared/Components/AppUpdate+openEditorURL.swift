//
//  AppUpdate+openEditorURL.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//
import SwiftUI
import os
import Combine

extension AppUpdate {
    static func openEditorURL(
        state: AppModel,
        url: URL,
        range: NSRange
    ) -> Change<AppModel, AppAction> {
        // Don't follow links while editing. Instead, select the link.
        //
        // When editing, you usually don't want to follow a link, you
        // want to tap into it to edit it. Also, we don't want to follow a
        // link in the middle of an edit and lose changes.
        //
        // Other approaches we could take in future:
        // - Save before following
        // - Have a disclosure step before following (like Google Docs)
        // For now, I think this is the best approach.
        //
        // 2021-09-23 Gordon Brander
        if state.focus == .editor {
            let fx: AnyPublisher<AppAction, Never> = Just(
                AppAction.setEditorSelection(range)
            ).eraseToAnyPublisher()
            return Change(state: state, fx: fx)
        } else {
            if Slashlink.isSlashlinkURL(url) {
                // If this is a Subtext URL, then commit a search for the
                // corresponding query
                let fx: AnyPublisher<AppAction, Never> = Just(
                    AppAction.commitSearch(
                        query: Slashlink.urlToProse(url)
                    )
                ).eraseToAnyPublisher()
                return Change(state: state, fx: fx)
            } else {
                UIApplication.shared.open(url)
                return Change(state: state)
            }
        }
    }
}
