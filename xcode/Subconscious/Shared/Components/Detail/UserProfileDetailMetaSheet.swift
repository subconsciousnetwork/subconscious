//
//  UserProfileMetaSheet.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI
import ObservableStore

struct MetaTableItemShareLinkView: View {
    var label: String
    var item: String
    
    var body: some View {
        ShareLink(item: item) {
            Label(
                label,
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
    }
}

struct MetaTableItemButtonView: View {
    var label: String
    var systemImage: String
    var action: () -> Void
    var role: ButtonRole? = nil
    
    var body: some View {
        Button(
            role: role,
            action: action
        ) {
            Label(
                label,
                systemImage: systemImage
            )
        }
        .buttonStyle(RowButtonStyle())
    }
}

struct UserProfileMetaSheetDetailsView: View {
    var user: UserProfile
    var ipfsHash: String
    var gatewayUrl: String
    
    var body: some View {
        DidQrCodeView(did: user.did, color: Color.secondary)
            .frame(maxWidth: 128)
        
        Spacer(minLength: AppTheme.padding)
        
        MetaTableView {
            Button(
                action: {},
                label: {
                    Label(
                        ipfsHash,
                        systemImage: "number"
                    )
                    .labelStyle(RowLabelStyle())
                }
            )
            .disabled(true)
            .buttonStyle(RowButtonStyle())
            
            Button(
                action: {},
                label: {
                    HStack {
                        Text(user.did.did)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "key")
                    }
                }
            )
            .disabled(true)
            .buttonStyle(RowButtonStyle())
            
            Button(
                action: {},
                label: {
                    HStack {
                        Text(gatewayUrl)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "network")
                    }
                }
            )
            .disabled(true)
            .buttonStyle(RowButtonStyle())
        }
        
    }
}

struct UserProfileDetailMetaSheet: View {
    @Environment(\.dismiss) private var dismiss
    var state: UserProfileDetailMetaSheetModel
    var profile: UserProfileDetailModel
    var followingUser: Bool
    var send: (UserProfileDetailMetaSheetAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    if let user = profile.user {
                        HStack {
                            Text("@\(user.petname.verbatim)")
                                .foregroundColor(.secondary)
                            if user.category == .you {
                            Text("(you)")
                                .foregroundColor(.secondary)
                            }
                        }
                        .font(.callout)
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
                            MetaTableItemShareLinkView(label: "Share DID", item: user.did.did)
                            
                            // None of these actions make sense to apply to yourself
                            if user.category != .you {
                                if followingUser {
                                    MetaTableItemButtonView(
                                        label: "Unfollow",
                                        systemImage: "person.2.slash",
                                        action: {
                                            send(.requestUnfollow(petname: user.petname))
                                        },
                                        role: .destructive
                                    )
                                } else {
                                    MetaTableItemButtonView(
                                        label: "Follow",
                                        systemImage: "person.badge.plus",
                                        action: {
                                            send(.requestFollow(did: user.did))
                                        }
                                    )
                                }
                                
                                MetaTableItemButtonView(
                                    label: "Block",
                                    systemImage: "hand.raised",
                                    action: {},
                                    role: .destructive
                                )
                            }
                            
                        }
                        
                        if Config.default.userProfileDetailsTable {
                            if state.isDetailsTablePresented {
                                Spacer(minLength: AppTheme.padding)
                                
                                UserProfileMetaSheetDetailsView(
                                    user: user,
                                    ipfsHash: "Qmf412jQZiuVUtdgnB36FXF",
                                    gatewayUrl: "https://ben.subconscious.network"
                                )
                            }
                            
                            MetaTableView {
                                MetaTableItemButtonView(
                                    label: state.isDetailsTablePresented ? "Hide Details" : "Show Details",
                                    systemImage: "tablecells",
                                    action: {
                                        withAnimation {
                                            send(.presentDetailsTable(!state.isDetailsTablePresented))
                                        }
                                    }
                                )
                            }
                        }
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
    
    case presentDetailsTable(Bool)
}

struct UserProfileDetailMetaSheetModel: ModelProtocol {
    typealias Action = UserProfileDetailMetaSheetAction
    typealias Environment = AppEnvironment
    
    /// Is delete confirmation dialog presented?
    var isDeleteConfirmationDialogPresented = false
    
    var isDetailsTablePresented = false
    
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
        case .presentDetailsTable(let presented):
            var model = state
            model.isDetailsTablePresented = presented
            return Update(state: model)
        }
    }
}
