//
//  AppUpdate+setLinkSearch.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func setLinkSearch(
        state: AppModel,
        text: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.linkSearchText = text

        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .searchSuggestions(query: text)
            .map({ suggestions in
                AppAction.setLinkSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    AppAction.linkSuggestionsFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }
}
