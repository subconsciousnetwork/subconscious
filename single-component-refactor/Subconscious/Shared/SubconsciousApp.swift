//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import os

@main
struct SubconsciousApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    state: .init(
                        suggestions: [
                            .search("El"),
                            .entry("Elm discourages deeply nested records"),
                            .entry("Elm a very long page title that should get truncated"),
                            .entry("Elm app architecture"),
                            .search("Elm"),
                            .search("Elephant")
                        ]
                    ),
                    logger: Logger.init(
                        subsystem: "com.subconscious",
                        category: "store"
                    ),
                    debug: false
                )
            )
        }
    }
}
