//
//  AppUpdate+listRecent.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func listRecent(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .listRecentEntries()
            .map({ entries in
                AppAction.setRecent(entries)
            })
            .catch({ error in
                Just(
                    .listRecentFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }
}
