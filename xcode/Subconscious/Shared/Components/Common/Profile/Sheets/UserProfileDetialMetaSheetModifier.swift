//
//  UserProfileDetialMetaSheetModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 3/11/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct UserProfileDetialMetaSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isMetaSheetPresented,
                    tag: UserProfileDetailAction.presentMetaSheet
                )
            ) {
                UserProfileDetailMetaSheet(
                    store: store.viewStore(
                        get: \.metaSheet,
                        tag: UserProfileDetailMetaSheetCursor.tag
                    )
                )
            }
    }
}

