//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import Sentry
import OSLog

@main
struct SubconsciousApp: App {
    init() {
        NoosphereLogProxy.connect()
    }

    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}
