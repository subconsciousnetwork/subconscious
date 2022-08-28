//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI

/// Top-level view for app
struct AppView: View {
    @ObservedObject var store: AppStore
    @Environment(\.scenePhase) var scenePhase: ScenePhase

    var body: some View {
        TabView {
            FeedView(
                store: store
            )
            .tabItem {
                Label("Feed", systemImage: "newspaper")
            }
            NotebookView(
                store: store.viewStore(
                    get: \.notebook,
                    tag: NotebookCursor.tag
                )
            )
            .tabItem {
                Label("Notes", systemImage: "folder")
            }
        }
        .disabled(!store.state.isReadyForInteraction)
        .font(Font(UIFont.appText))
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
