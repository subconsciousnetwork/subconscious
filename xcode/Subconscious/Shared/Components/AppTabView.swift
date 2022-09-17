//
//  AppTabView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/17/22.
//

import SwiftUI
import ObservableStore

/// The new tabbed view.
/// Used when `Config.appTabs` is true.
struct AppTabView: View {
    @ObservedObject var store: Store<AppModel>

    var body: some View {
        TabView {
            FeedView(
                store: ViewStore(
                    store: store,
                    cursor: FeedCursor.self
                )
            )
            .tabItem {
                Label("Feed", systemImage: "newspaper")
            }
            NotebookView(
                store: ViewStore(
                    store: store,
                    cursor: NotebookCursor.self
                )
            )
            .tabItem {
                Label("Notes", systemImage: "folder")
            }
        }
    }
}
