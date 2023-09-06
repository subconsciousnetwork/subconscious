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
            HomeProfileView(app: store)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            if Config.default.feed {
                FeedView(parent: store)
                    .tabItem {
                        Label("Feed", systemImage: "newspaper")
                    }
            }
            NotebookView(app: store)
                .tabItem {
                    Label("Notes", systemImage: "folder")
                }
        }
    }
}
