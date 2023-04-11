//
//  UserProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 27/3/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct ProfileStatisticView: View {
    var label: String
    var count: Int
    
    var body: some View {
        HStack(spacing: AppTheme.unit) {
            Text("\(count)").bold()
            Text(label).foregroundColor(.secondary)
        }
    }
}

enum FollowUserSheetAction: Equatable {
    case populate(UserProfile)
    case followUserForm(FollowUserFormAction)
    case requestFollow
}

struct FollowUserSheetEnvironment {
    var addressBook: AddressBookService
}

struct FollowUserSheetModel: ModelProtocol {
    typealias Action = FollowUserSheetAction
    typealias Environment = FollowUserSheetEnvironment
    
    var followUserForm: FollowUserFormModel = FollowUserFormModel()
    
    static func update(state: Self, action: Action, environment: Environment) -> Update<Self> {
        switch action {
        case .populate(let user):
            return update(
                state: state,
                actions: [
                    .followUserForm(.didField(.setValue(input: user.did.did))),
                    .followUserForm(.petnameField(.setValue(input: user.petname.verbatim)))
                ],
                environment: environment
            )
        case .followUserForm(let action):
            return FollowUserSheetFormCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .requestFollow:
            return Update(state: state)
        }
    }
}

struct FollowUserSheetFormCursor: CursorProtocol {
    typealias Model = FollowUserSheetModel
    typealias ViewModel = FollowUserFormModel
    
    static func get(state: FollowUserSheetModel) -> FollowUserFormModel {
        state.followUserForm
    }
    
    static func set(state: FollowUserSheetModel, inner: FollowUserFormModel) -> FollowUserSheetModel {
        var model = state
        model.followUserForm = inner
        return model
    }
    
    static func tag(_ action: FollowUserFormAction) -> FollowUserSheetAction {
        .followUserForm(action)
    }
}

struct FollowUserSheetSheetCursor: CursorProtocol {
    typealias Model = UserProfileDetailModel
    typealias ViewModel = FollowUserSheetModel

    static func get(state: Model) -> ViewModel {
        state.followUserSheet
    }

    static func set(
        state: Model,
        inner: ViewModel
    ) -> Model {
        var model = state
        model.followUserSheet = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .followUserSheet(action)
        }
    }
}

struct FollowUserSheet: View {
    var state: FollowUserSheetModel
    var send: (FollowUserSheetAction) -> Void
    var user: UserProfile
    
    var body: some View {
        VStack(alignment: .center, spacing: AppTheme.unit2) {
            ProfilePic(image: Image(user.pfp))
            
            Text(user.did.did)
                .font(.caption.monospaced())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            ValidatedTextField(
                placeholder: "@petname",
                text: Binding(
                    get: { state.followUserForm.petname.value },
                    send: send,
                    tag: { input in
                        .followUserForm(.petnameField(.setValue(input: input)))
                    }
                ),
                caption: "You already follow @petname"
            )
            .textFieldStyle(.roundedBorder)
            
            Spacer()
            
            Button(
                action: { send(.requestFollow) },
                label: { Text("Follow @petname-2") }
            )
            .buttonStyle(PillButtonStyle())
        }
        .padding(AppTheme.padding)
        .presentationDetents([.fraction(0.33)])
        .onAppear {
            send(.populate(user))
        }
    }
}

struct UserProfileView: View {
    var state: UserProfileDetailModel
    var send: (UserProfileDetailAction) -> Void
    
    let onNavigateToNote: (MemoAddress) -> Void
    let onNavigateToUser: (MemoAddress) -> Void
    
    let onProfileAction: (UserProfile, UserProfileAction) -> Void
    
    var body: some View {
        let columnRecent = TabbedColumnItem(
            label: "Recent",
            view: Group {
                if let user = state.user {
                    ForEach(state.recentEntries, id: \.id) { entry in
                        StoryEntryView(
                            story: StoryEntry(
                                author: user,
                                entry: entry
                            ),
                            action: { address, excerpt in onNavigateToNote(address) }
                        )
                    }
                }
            }
        )
        
        let columnTop = TabbedColumnItem(
            label: "Top",
            view: Group {
                if let user = state.user {
                    ForEach(state.topEntries, id: \.id) { entry in
                        StoryEntryView(
                            story: StoryEntry(
                                author: user,
                                entry: entry
                            ),
                            action: { address, excerpt in onNavigateToNote(address) }
                        )
                    }
                }
            }
        )
         
        let columnFollowing = TabbedColumnItem(
            label: "Following",
            view: Group {
                ForEach(state.following, id: \.user.did) { follow in
                    StoryUserView(
                        story: follow,
                        action: { address, _ in onNavigateToUser(address) },
                        profileAction: onProfileAction
                    )
                }
            }
        )
        
        VStack(alignment: .leading, spacing: 0) {
            if let user = state.user {
                UserProfileHeaderView(
                    user: user,
                    statistics: state.statistics,
                    isFollowingUser: state.isFollowingUser,
                    action: { action in
                        onProfileAction(user, action)
                    }
                )
                .padding(AppTheme.padding)
            }
            
            TabbedThreeColumnView(
                columnA: columnRecent,
                columnB: columnTop,
                columnC: columnFollowing,
                selectedColumnIndex: state.selectedTabIndex,
                changeColumn: { index in
                    send(.tabIndexSelected(index))
                }
            )
        }
        .navigationTitle(state.user?.petname.verbatim ?? "loading...")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            if let user = state.user {
                DetailToolbarContent(
                    address: Slashlink(petname: user.petname).toPublicMemoAddress(),
                    defaultAudience: .public,
                    onTapOmnibox: {
                        send(.presentMetaSheet(true))
                    }
                )
            }
        })
        .sheet(
            isPresented: Binding(
                get: { state.isFollowSheetPresented },
                send: send,
                tag: UserProfileDetailAction.presentFollowSheet
            )
        ) {
            if let user = state.user {
                FollowUserSheet(
                    state: state.followUserSheet,
                    send: { _ in },
                    user: user
                )
            }
        }
        .sheet(
            isPresented: Binding(
                get: { state.isMetaSheetPresented },
                send: send,
                tag: UserProfileDetailAction.presentMetaSheet
            )
        ) {
            UserProfileDetailMetaSheet(
                state: state.metaSheet,
                profile: state,
                isFollowingUser: state.isFollowingUser,
                send: Address.forward(
                    send: send,
                    tag: UserProfileDetailMetaSheetCursor.tag
                )
            )
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(
            state: UserProfileDetailModel(isFollowSheetPresented: true),
            send: { _ in },
            onNavigateToNote: { _ in print("navigate to note") },
            onNavigateToUser: { _ in print("navigate to user") },
            onProfileAction: { user, action in print("profile action") }
        )
    }
}
