//
//  AppUpdate+Appear.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func appear(state: AppModel) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.debug(
            "Documents: \(AppEnvironment.documentURL)"
        )
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .migrate()
            .map({ success in
                AppAction.databaseReady(success)
            })
            .catch({ _ in
                Just(AppAction.rebuildDatabase)
            })
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }
}
