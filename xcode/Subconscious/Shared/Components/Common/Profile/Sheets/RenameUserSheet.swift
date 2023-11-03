//
//  RenameUserSheet.swift
//  Subconscious
//
//  Created by Ben Follington on 3/11/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct RenameSheetModifier: ViewModifier {
    @ObservedObject var store: Store<UserProfileDetailModel>
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: store.binding(
                    get: \.isRenameSheetPresented,
                    tag: UserProfileDetailAction.presentRenameSheet
                )
            ) {
                FollowUserSheet(
                    store: store.viewStore(
                        get: \.renameUserSheet,
                        tag: RenameUserSheetCursor.tag
                    ),
                    label: Text("Rename")
                )
            }
    }
}

struct RenameUserSheetCursor: CursorProtocol {
    typealias Model = UserProfileDetailModel
    typealias ViewModel = FollowUserSheetModel
    
    static func get(state: Model) -> ViewModel {
        state.renameUserSheet
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.renameUserSheet = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .submit:
            return .attemptRename
        default:
            return .renameUserSheet(action)
        }
    }
}

