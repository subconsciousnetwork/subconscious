//
//  FollowNewUserSheetModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 3/11/2023.
//

import SwiftUI
import ObservableStore

struct FollowNewUserSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isFollowNewUserFormSheetPresented,
                    tag: UserProfileDetailAction.presentFollowNewUserFormSheet
                )
            ) {
                FollowNewUserFormSheetView(
                    store: store.viewStore(
                        get: \.followNewUserFormSheet,
                        tag: FollowNewUserFormSheetCursor.tag
                    )
                )
            }
            
    }
}
