//
//  UserProfileMetaSheet.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI
import ObservableStore

struct UserProfileDetailMetaSheet: View {
    @Environment(\.dismiss) private var dismiss
    var state: UserProfileDetailMetaSheetModel
    var profile: UserProfileDetailModel
    var send: (UserProfileDetailMetaSheetAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    if let user = profile.user {
                        HStack {
                            Text("@\(user.petname.verbatim)")
                                .foregroundColor(.secondary)
                        }
                        .font(.callout)
                        
                        Text(user.did.description)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                CloseButtonView(action: { dismiss() })
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .center) {
                    if let user = profile.user {
                        MetaTableView {
                            ShareLink(item: user.did.did) {
                                Label(
                                    "Share DID",
                                    systemImage: "square.and.arrow.up"
                                )
                                .labelStyle(RowLabelStyle())
                            }
                            .padding(
                                EdgeInsets(
                                    top: 0,
                                    leading: AppTheme.padding,
                                    bottom: 0,
                                    trailing: AppTheme.padding
                                )
                            )
                            .frame(height: AppTheme.unit * 11) // There has to be a better way...
                            
                            Button(
                                role: .destructive,
                                action: {
                                    send(.presentDeleteConfirmationDialog(true))
                                }
                            ) {
                                Label(
                                    "Follow/Unfollow",
                                    systemImage: "trash"
                                )
                            }
                            .buttonStyle(RowButtonStyle())
                        }
                    
                        DidQrCodeView(did: user.did, color: Color.secondary)
                            .frame(maxWidth: 128)
                    }
                }
                .padding()
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium, .large])
        .confirmationDialog(
            "Are you sure you want to unfollow \(profile.user?.petname.verbatim ?? "unknown")",
            isPresented: Binding(
                get: { state.isDeleteConfirmationDialogPresented },
                send: send,
                tag: UserProfileDetailMetaSheetAction.presentDeleteConfirmationDialog
            ),
            titleVisibility: .visible
        ) {
            Button(
                role: .destructive,
                action: {
                    guard let petname = profile.user?.petname else {
                        return
                    }
                    
                    send(.requestUnfollow(petname: petname))
                }
            ) {
                Text("Unfollow @\(profile.user?.petname.verbatim ?? "unknown")")
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

enum UserProfileDetailMetaSheetAction: Hashable {
    /// Show/hide delete confirmation dialog
    case presentDeleteConfirmationDialog(Bool)
    /// Request to follow this user
    /// Should be handled by parent component.
    case requestFollow(did: Did)
    /// Request to unfollow this user
    /// Should be handled by parent component.
    case requestUnfollow(petname: Petname)
}

struct UserProfileDetailMetaSheetModel: ModelProtocol {
    typealias Action = UserProfileDetailMetaSheetAction
    typealias Environment = AppEnvironment
    
    /// Is delete confirmation dialog presented?
    var isDeleteConfirmationDialogPresented = false
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> ObservableStore.Update<Self> {
        switch action {
        case .requestUnfollow(petname: let petname):
            return Update(state: state)
        case .requestFollow(did: let did):
            return Update(state: state)
        case .presentDeleteConfirmationDialog(let presented):
            var model = state
            model.isDeleteConfirmationDialogPresented = presented
            return Update(state: model)
        }
    }
}
