//
//  DiscoverNavigationView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/2/2024.
//

import Foundation
import ObservableStore
import SwiftUI

struct DiscoverNavigationView: View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<DiscoverModel>
    @Environment(\.colorScheme) var colorScheme
    
    var detailStack: ViewStore<DetailStackModel> {
        store.viewStore(
            get: DiscoverDetailStackCursor.get,
            tag: DiscoverDetailStackCursor.tag
        )
    }
   
    var body: some View {
        DetailStackView(app: app, store: detailStack) {
            VStack(alignment: .leading) {
                Text("hi")
            }
            .padding(AppTheme.padding)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                MainToolbar(
                    app: app
                )
            }
        }
    }
}

