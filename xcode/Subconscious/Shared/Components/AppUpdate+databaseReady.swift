//
//  AppUpdate+databaseReady.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//
import SwiftUI
import os
import Combine

extension AppUpdate {
    static func databaseReady(
        state: AppModel,
        success: SQLite3Migrations.MigrationSuccess
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.isDatabaseReady = true
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .syncDatabase()
            .map({ changes in
                AppAction.syncSuccess(changes)
            })
            .catch({ error in
                Just(AppAction.syncFailure(error.localizedDescription))
            })
            .merge(
                with: Just(AppAction.setSearch("")),
                Just(AppAction.setLinkSearch("")),
                Just(AppAction.listRecent)
            )
            .eraseToAnyPublisher()
        if success.from != success.to {
            AppEnvironment.logger.log(
                "Migrated database: \(success.from)->\(success.to)"
            )
        }
        AppEnvironment.logger.log("File sync started")
        return Change(state: model, fx: fx)
    }
}
