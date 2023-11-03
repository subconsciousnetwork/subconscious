//
//  FollowUserSheetModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 3/11/2023.
//

import SwiftUI
import ObservableStore

struct FollowSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>

    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isFollowSheetPresented,
                    tag: UserProfileDetailAction.presentFollowSheet
                )
            ) {
                FollowUserSheet(
                    store: store.viewStore(
                        get: \.followUserSheet,
                        tag: FollowUserSheetCursor.tag
                    ),
                    label: Text("Follow")
                )
            }
    }
}
