//
//  AppTabView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/17/22.
//

import SwiftUI
import ObservableStore
import Combine

enum AppTab: String {
    case feed
    case notebook
    case profile
}

struct AppTabView: View {
    @ObservedObject var store: Store<AppModel>

    var body: some View {
        TabView(
            selection: Binding(
                get: { store.state.selectedAppTab },
                send: store.send,
                tag: AppAction.setSelectedAppTab
            )
        ) {
            FeedView(app: store)
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }
                .tag(AppTab.feed)
            
            NotebookView(app: store)
                .tabItem {
                    Label("Notes", systemImage: "folder")
                }
                .tag(AppTab.notebook)
            
            HomeProfileView(app: store)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)
        }
    }
}
