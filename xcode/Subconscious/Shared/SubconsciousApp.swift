//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//

import SwiftUI

@main
struct SubconsciousApp: App {
    @StateObject private var store: AppStore = AppStore(
        state: .init(),
        reducer: updateApp,
        environment: .init()
    )

    init() {
        print("SubconsciousApp.init")
    }
    
    var body: some Scene {
        print("SubconsciousApp.body")
        return WindowGroup {
            ContentView(store: store).equatable()
        }
    }
}
