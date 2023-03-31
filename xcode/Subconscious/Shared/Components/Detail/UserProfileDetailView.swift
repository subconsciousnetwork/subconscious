//
//  UserProfileDetailView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI
import ObservableStore

/// Display a read-only memo detail view.
/// Used for content from other spheres that we don't have write access to.
struct UserProfileDetailView: View {
    @StateObject private var store = Store(
        state: UserProfileDetailModel(),
        environment: AppEnvironment.default
    )

    var description: UserProfileDetailDescription
    var notify: (UserProfileDetailNotification) -> Void
    
    func onNavigateToNote(address: MemoAddress) {
        notify(.requestDetail(.from(address: address, fallback: "")))
    }
    
    func onNavigateToUser(address: MemoAddress) {
        notify(.requestDetail(.profile(UserProfileDetailDescription(address: address))))
    }

    var body: some View {
        UserProfileView(
            state: store.state,
            send: store.send,
            onNavigateToNote: self.onNavigateToNote,
            onNavigateToUser: self.onNavigateToUser
        )
    }
}

/// Actions forwarded up to the parent context to notify it of specific
/// lifecycle events that happened within our component.
enum UserProfileDetailNotification: Hashable {
    case requestDetail(MemoDetailDescription)
}

/// A description of a memo detail that can be used to set up the memo
/// detal's internal state.
struct UserProfileDetailDescription: Hashable {
    var address: MemoAddress
    var initialProfileTabIndex: Int = 0 // TODO: change to enum
}

enum UserProfileDetailAction: Hashable {
    case populate(UserProfile, UserProfileStatistics?)
    case tabIndexSelected(Int)
    case presentMetaSheet(Bool)
    case metaSheet(UserProfileDetailMetaSheetAction)
}

struct UserProfileStatistics: Equatable, Codable, Hashable {
    let noteCount: Int
    let backlinkCount: Int
    let followingCount: Int
}

enum UserCategory: Equatable, Codable, Hashable, CaseIterable {
    case human
    case geist
    case you
}

struct UserProfile: Equatable, Codable, Hashable {
    let did: Did
    let petname: Petname
    let pfp: String
    let bio: String
    let category: UserCategory
}

struct UserProfileDetailModel: ModelProtocol {
    typealias Action = UserProfileDetailAction
    typealias Environment = AppEnvironment
    
    var metaSheet: UserProfileDetailMetaSheetModel = UserProfileDetailMetaSheetModel()
    var selectedTabIndex = 0
    var isMetaSheetPresented = false
    
    var user: UserProfile? = UserProfile(
        did: Did("did:key:123")!,
        petname: Petname("ben")!,
        pfp: "pfp-dog",
        bio: "Henlo world.",
        category: .human
    )
    var followingUser: Bool = false
    
    var recentEntries: [EntryStub] = (1...10).map { _ in
        EntryStub.dummyData()
    }
    var topEntries: [EntryStub] = (1...10).map { _ in
        EntryStub.dummyData()
    }
    var following: [StoryUser] = (1...10).map { _ in
        StoryUser.dummyData()
    }
    
    var statistics: UserProfileStatistics? = UserProfileStatistics(
        noteCount: 123,
        backlinkCount: 64,
        followingCount: 19
    )

    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .metaSheet(let action):
            return UserProfileDetailMetaSheetCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .populate(let user, let statistics):
            var model = state
            model.user = user
            model.statistics = statistics
            
            // TODO: move this to the model init when we can init using a closure https://github.com/subconsciousnetwork/ObservableStore/pull/30
            if user.category == .you {
                model.selectedTabIndex = 2
            }
            
            return Update(state: model)
            
        case .tabIndexSelected(let index):
            var model = state
            model.selectedTabIndex = index
            return Update(state: model)
        case .presentMetaSheet(let presented):
            var model = state
            model.isMetaSheetPresented = presented
            return Update(state: model)
        }
    }
}
