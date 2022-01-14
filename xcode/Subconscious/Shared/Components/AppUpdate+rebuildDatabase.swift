//
//  AppUpdate+rebuildDatabase.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func rebuildDatabase(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.warning(
            "Database is broken or has wrong schema. Attempting to rebuild."
        )
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .delete()
            .flatMap({ _ in
                AppEnvironment.database.migrate()
            })
            .map({ success in
                AppAction.databaseReady(success)
            })
            .catch({ error in
                Just(AppAction.rebuildDatabaseFailure(
                    error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }
}
