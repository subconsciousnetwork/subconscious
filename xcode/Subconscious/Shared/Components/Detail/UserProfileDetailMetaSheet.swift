//
//  UserProfileMetaSheet.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI
import ObservableStore

struct MetaTableLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon.frame(
                width: AppTheme.icon,
                height: AppTheme.icon
            )
            Spacer()
            configuration.title
        }
        .padding(RowButtonStyle.insets)
    }
}

struct MetaTableMetadataLabelView: View {
    var title: String
    
    var body: some View {
        Label(title: {
            Text(title)
                .font(.callout.monospaced())
        }, icon: {
            Image(systemName: "key")
        })
        .labelStyle(MetaTableLabelStyle())
        .foregroundColor(.secondary)
    }
}

struct MetaTableItemShareLinkView: View {
    var label: String
    var item: String
    
    var body: some View {
        ShareLink(item: item) {
            Label(
                label,
                systemImage: "square.and.arrow.up"
            )
        }
        .buttonStyle(RowButtonStyle())
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
    var qrCodeSize = 128.0
    
    var body: some View {
        DidQrCodeView(did: user.did, color: Color.gray)
            .frame(maxWidth: qrCodeSize)
        
        Spacer(minLength: AppTheme.padding)
        
        MetaTableView {
            MetaTableMetadataLabelView(title: user.did.did)
        }
    }
}

struct UserProfileDetailMetaSheet: View {
    @Environment(\.dismiss) private var dismiss
    var state: UserProfileDetailMetaSheetModel
    var profile: UserProfileDetailModel
    var isFollowingUser: Bool
    var send: (UserProfileDetailMetaSheetAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    if let user = profile.user {
                        if let path = profile.traversalPath,
                           let slashlink = Slashlink(petname: path) {
                            SlashlinkBylineView(slashlink: slashlink).theme(
                                petname: Color.primary,
                                slug: Color.secondary
                            )
                        }
                        
                        if user.category == .you {
                            SlashlinkBylineView(slashlink: Slashlink.yourProfile).theme(
                                petname: Color.primary,
                                slug: Color.secondary
                            )
                        }
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
                            MetaTableItemShareLinkView(label: "Share Link", item: Slashlink(petname: user.petname).verbatimMarkup)
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
        .presentationDetents([.medium])
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
