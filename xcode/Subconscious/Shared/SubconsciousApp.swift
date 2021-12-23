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
    init() {
        // Set global UINavigationBar appearance.
        // This customizes the appearance of NavigationView as well.
        // SwiftUI does not yet have a way of customizing this via declarative
        // SwiftUI APIs, so we use this older API instead.
        // https://developer.apple.com/documentation/uikit/uinavigationbar
        // https://developer.apple.com/documentation/uikit/uinavigationcontroller/customizing_your_app_s_navigation_bar
        // 2021-12-12 Gordon Brander
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.background)
        appearance.titleTextAttributes = [.font: UIFont.appText]
        appearance.largeTitleTextAttributes = [.font: UIFont.appLargeTitle]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    state: .init(),
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
