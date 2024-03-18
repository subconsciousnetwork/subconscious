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
    case discover
}

struct AppTabView: View {
    @ObservedObject var store: Store<AppModel>
    // For performance purposes we proxy this state through to the store
    // in the background. This is a stop-gap solution until we find a
    // general approach to fine-grained reactivity.
    @State var selectedTab: AppTab = .notebook

    var body: some View {
        TabView(selection: $selectedTab) {
            DeckView(app: store)
                .tabItem {
                    Label("Deck", systemImage: "square.stack.3d.up.fill")
                }
                .tag(AppTab.deck)
            
            DiscoverView(app: store)
                .tabItem {
                    Label("Discover", systemImage: "globe")
                }
                .tag(AppTab.discover)
            
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
        .onAppear {
            selectedTab = store.state.selectedAppTab
        }
        .onChange(of: selectedTab) { v in
            store.send(.setSelectedAppTab(selectedTab))
        }
    }
}
