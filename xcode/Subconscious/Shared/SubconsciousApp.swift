//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import os
import Combine

@main
struct SubconsciousApp: App {
    var store: Store<AppModel, AppAction>
    var keyboardService: KeyboardService

    init() {
        self.keyboardService = KeyboardService()

        let services: AnyPublisher<AppAction, Never> = self.keyboardService
            .state
            .map(AppAction.changeKeyboardState)
            .eraseToAnyPublisher()

        self.store = Store(
            update: AppUpdate.update,
            state: AppModel(),
            subscription: services,
            logger: Logger.init(
                subsystem: "com.subconscious",
                category: "store"
            ),
            debug: false
        )
    }

    var body: some Scene {
        WindowGroup {
            AppView(
                store: self.store
            )
        }
    }
}
