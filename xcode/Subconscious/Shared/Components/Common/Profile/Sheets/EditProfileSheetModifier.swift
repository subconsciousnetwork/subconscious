//
//  EditProfileSheetModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 3/11/2023.
//

import Foundation
import ObservableStore
import SwiftUI

struct EditProfileSheetModifier: ViewModifier {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isEditProfileSheetPresented,
                    tag: UserProfileDetailAction.presentEditProfile
                )
            ) {
                EditProfileSheet(
                    store: store.viewStore(
                        get: \.editProfileSheet,
                        tag: EditProfileSheetCursor.tag
                    )
                )
            }
            .onReceive(
                store.actions.compactMap(AppAction.from),
                perform: app.send
            )
    }
}
