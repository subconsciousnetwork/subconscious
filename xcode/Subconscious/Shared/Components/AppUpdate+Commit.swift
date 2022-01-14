//
//  AppUpdate+Commit.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func commit(
        state: AppModel,
        query: String,
        slug: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        resetEditor(&model)
        model.entryURL = nil
        model.searchText = ""
        model.isSearchShowing = false
        model.isDetailShowing = true

        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .search(
                query: query,
                slug: slug
            )
            .map({ results in
                AppAction.setDetail(results)
            })
            .catch({ error in
                Just(AppAction.detailFailure(error.localizedDescription))
            })
            .merge(with: Just(AppAction.setSearch("")))
            .eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }
}

