//
//  AppUpdate+deleteEntrySuccess.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//

import SwiftUI
import os
import Combine

extension AppUpdate {
    static func deleteEntrySuccess(
        state: AppModel,
        slug: String
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.log("Deleted entry: \(slug)")
        //  Refresh lists in search fields after delete.
        //  This ensures they don't show the deleted entry.
        let fx: AnyPublisher<AppAction, Never> = Just(AppAction.setSearch(""))
            .merge(with: Just(AppAction.setLinkSearch("")))
            .eraseToAnyPublisher()
        return Change(
            state: state,
            fx: fx
        )
    }
}
