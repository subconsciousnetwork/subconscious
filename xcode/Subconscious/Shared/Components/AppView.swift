//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import ObservableStore

/// Top-level view for app
struct AppView: View {
    @ObservedObject var store: Store<AppModel>
    @Environment(\.scenePhase) var scenePhase: ScenePhase

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if Config.default.appTabs {
                    AppTabView(store: store)
                } else {
                    NotebookView(
                        store: ViewStore(
                            store: store,
                            cursor: NotebookCursor.self
                        )
                    )
                }
            }
            .zIndex(0)
            if store.state.sphereIdentity == nil {
                FirstRunView(
                    store: Store(
                        state: FirstRunModel(),
                        environment: store.environment
                    ),
                    done: {}
                )
                .zIndex(1)
            }
        }
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2022-02-08 Gordon Brander
        .onChange(of: self.scenePhase) { phase in
            store.send(AppAction.scenePhaseChange(phase))
        }
        .onAppear {
            store.send(.appear)
        }
    }
}
