//
//  AppTabView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/17/22.
//

import SwiftUI
import ObservableStore
import Combine

enum Tab: String {
    case feed
    case notebook
}

// Adapted from https://medium.com/geekculture/move-to-top-of-tab-on-selecting-same-tab-from-tab-bar-in-swiftui-a2b2cfd33872
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
    @StateObject var appTabs: AppTabState = AppTabState()

    var body: some View {
        TabView(selection: $appTabs.tabSelected) {
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
        .onChange(of: appTabs.popStackToNavigationRoot, perform: { _ in
            switch (appTabs.tabSelected) {
            case .notebook:
                store.send(.requestNotebookRoot)
            case .feed:
                store.send(.requestFeedRoot)
            }
        })
    }
}
