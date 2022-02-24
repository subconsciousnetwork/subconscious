//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import os
import Combine

typealias SubconsciousStore = Store<AppModel, AppEnvironment, AppAction>

@main
struct SubconsciousApp: App {
    @StateObject private var store: SubconsciousStore = Store(
        update: AppUpdate.debug,
        state: AppModel(),
        environment: AppEnvironment()
    )

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
