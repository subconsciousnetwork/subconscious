//
//  AppUpdate+save.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func save(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.focus = nil
        if let entryURL = model.entryURL {
            // Parse editorAttributedText to entry.
            // TODO refactor model to store entry instead of attributedText.
            let entry = SubtextFile(
                url: entryURL,
                content: model.editorAttributedText.string
            )
            let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
                .writeEntry(
                    entry: entry
                )
                .map({ _ in
                    AppAction.saveSuccess(entryURL)
                })
                .catch({ error in
                    Just(
                        AppAction.saveFailure(
                            url: entryURL,
                            message: error.localizedDescription
                        )
                    )
                })
                .eraseToAnyPublisher()
            return Change(state: model, fx: fx)
        } else {
            AppEnvironment.logger.warning(
                """
                Could not save. No URL set for entry.
                It should not be possible to reach this state.
                """
            )
            return Change(state: model)
        }
    }
}
