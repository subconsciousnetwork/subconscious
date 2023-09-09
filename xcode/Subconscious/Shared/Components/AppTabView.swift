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
}

// Adapted from https://medium.com/geekculture/move-to-top-of-tab-on-selecting-same-tab-from-tab-bar-in-swiftui-a2b2cfd33872
class AppTabState: ObservableObject {
    @Published var tabSelected: AppTab = .feed {
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
        }
    }
}
