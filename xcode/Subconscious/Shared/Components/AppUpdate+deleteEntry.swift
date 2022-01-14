//
//  AppUpdate+deleteEntry.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func deleteEntry(
        state: AppModel,
        slug: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        if let index = model.recent.firstIndex(
            where: { stub in stub.id == slug }
        ) {
            model.recent.remove(at: index)
            let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
                .deleteEntry(slug: slug)
                .map({ _ in
                    AppAction.deleteEntrySuccess(slug)
                })
                .catch({ error in
                    Just(
                        AppAction.deleteEntryFailure(
                            error.localizedDescription
                        )
                    )
                })
                .eraseToAnyPublisher()
            return Change(state: model, fx: fx)
        } else {
            AppEnvironment.logger.log(
                "Failed to delete entry. No such id: \(slug)"
            )
            return Change(state: model)
        }
    }
}
