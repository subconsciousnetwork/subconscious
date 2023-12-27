//
//  AppTabView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/17/22.
//

import SwiftUI
import ObservableStore
import Combine

enum AppTab: String, Hashable {
    case deck
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

            DeckView(app: store)
                .tabItem {
                    Label("Deck", systemImage: "square.stack.3d.up.fill")
                }
                .tag(AppTab.deck)
            
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
