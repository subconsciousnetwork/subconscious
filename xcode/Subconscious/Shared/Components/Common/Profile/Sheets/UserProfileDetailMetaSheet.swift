//
//  UserProfileMetaSheet.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI
import ObservableStore

struct UserProfileMetaSheetDetailsView: View {
    var user: UserProfile
    var qrCodeSize = 240.0
    
    var body: some View {
        ShareableDidQrCodeView(did: user.did, color: Color.gray)
            .frame(maxWidth: qrCodeSize)
        
        Spacer(minLength: AppTheme.padding)
        
        MetaTableView {
            MetaTableMetadataLabelView(title: user.did.did)
        }
    }
}

struct UserProfileDetailMetaSheet: View {
    @Environment(\.dismiss) private var dismiss
    var store: ViewStore<UserProfileDetailMetaSheetModel>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    if let user = store.state.user {
                        SlashlinkDisplayView(
                            slashlink: user.address
                        ).theme(
                            base: Color.primary,
                            slug: Color.secondary
                        )
                    }
                }
                
                Spacer()
                
                CloseButtonView(action: { dismiss() })
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .center) {
                    if let user = store.state.user {
                        MetaTableView {
                            MetaTableItemShareLinkView(
                                label: "Share Link",
                                item: user.address.verbatimMarkup
                            )
                            Divider()
                            MetaTableItemShareLinkView(label: "Share DID", item: user.did.did)
                            // Add concepts such as "Block" or "Mute" here later?
                        }
                        
                        UserProfileMetaSheetDetailsView(
                            user: user
                        )
                    }
                }
                .padding()
                
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium, .large])
        .confirmationDialog(
            "Are you sure you want to unfollow \(store.state.user?.displayName ?? "")",
            isPresented: store.binding(
                get: \.isDeleteConfirmationDialogPresented,
                tag: UserProfileDetailMetaSheetAction.presentDeleteConfirmationDialog
            ),
            titleVisibility: .visible
        ) {
            Button(
                role: .destructive,
                action: {
                    guard let did = store.state.user?.did else {
                        return
                    }
                    
                    store.send(.requestUnfollow(did: did))
                }
            ) {
                Text("Unfollow \(store.state.user?.displayName ?? "")")
            }
        }
    }
}

struct UserProfileDetailMetaSheetCursor: CursorProtocol {
    typealias Model = UserProfileDetailModel
    typealias ViewModel = UserProfileDetailMetaSheetModel

    static func get(state: Model) -> ViewModel {
        state.metaSheet
    }

    static func set(
        state: Model,
        inner: ViewModel
    ) -> Model {
        var model = state
        model.metaSheet = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .metaSheet(action)
        }
    }
}

enum UserProfileDetailMetaSheetAction: Equatable, Hashable {
    case populate(_ user: UserProfile)
    /// Show/hide delete confirmation dialog
    case presentDeleteConfirmationDialog(Bool)
    /// Request to follow this user
    /// Should be handled by parent component.
    case requestFollow(did: Did)
    /// Request to unfollow this user
    /// Should be handled by parent component.
    case requestUnfollow(did: Did)
    
    case presentDetailsTable(Bool)
}

struct UserProfileDetailMetaSheetModel: ModelProtocol {
    typealias Action = UserProfileDetailMetaSheetAction
    typealias Environment = AppEnvironment
    
    var user: UserProfile? = nil
    
    /// Is delete confirmation dialog presented?
    var isDeleteConfirmationDialogPresented = false
    var isDetailsTablePresented = false
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> ObservableStore.Update<Self> {
        switch action {
        case let .populate(user):
            var model = state
            model.user = user
            return Update(state: model)
        case .requestUnfollow:
            return Update(state: state)
        case .requestFollow:
            return Update(state: state)
        case .presentDeleteConfirmationDialog(let presented):
            var model = state
            model.isDeleteConfirmationDialogPresented = presented
            return Update(state: model)
        case .presentDetailsTable(let presented):
            var model = state
            model.isDetailsTablePresented = presented
            return Update(state: model)
        }
    }
}
