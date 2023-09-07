//
//  AppTabView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/17/22.
//

import SwiftUI
import ObservableStore
import Combine

// Adapted from https://medium.com/geekculture/move-to-top-of-tab-on-selecting-same-tab-from-tab-bar-in-swiftui-a2b2cfd33872
enum Tab: String {
    case homeProfile
    case feed
    case notebook
}

class AppTabState: ObservableObject {
    @Published var tabSelected: Tab = .feed {
        didSet {
            if oldValue == tabSelected {
                popStackToNavigationRoot.toggle()
            }
        }
    }
    // This value will be toggled when a user selects the same tab twice in a row
    @Published var popStackToNavigationRoot: Bool = false
}

/// The new tabbed view.
/// Used when `Config.appTabs` is true.
struct AppTabView: View {
    @ObservedObject var store: Store<AppModel>
    @StateObject var tabStateHandler: AppTabState = AppTabState()

    var body: some View {
        TabView(selection: $tabStateHandler.tabSelected) {
            if Config.default.profileTab {
                HomeProfileView(app: store)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .tag(Tab.homeProfile)
            }
            
            if Config.default.feed {
                FeedView(app: store)
                    .tabItem {
                        Label("Feed", systemImage: "newspaper")
                    }
                    .tag(Tab.feed)
            }
            NotebookView(app: store)
                .tabItem {
                    Label("Notes", systemImage: "folder")
                }
                .tag(Tab.notebook)
        }
        .onChange(of: tabStateHandler.popStackToNavigationRoot, perform: { _ in
            switch (tabStateHandler.tabSelected) {
            case .homeProfile:
                store.send(.requestHomeProfile)
            case .notebook:
                store.send(.requestNotebookRoot)
            case .feed:
                store.send(.requestFeedRoot)
            }
        })
    }
}
