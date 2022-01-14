//
//  AppUpdate+setSearch.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func setSearch(
        state: AppModel,
        text: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.searchText = text
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .searchSuggestions(query: text)
            .map({ suggestions in
                AppAction.setSuggestions(suggestions)
            })
            .catch({ error in
                Just(.suggestionsFailure(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Change(state: model, fx: fx)
    }
}
