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
            user: store.state.user,
            articles: store.state.articles,
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
}

enum UserProfileDetailAction: Hashable {
    
}

struct UserProfileStatistics: Equatable {
    let noteCount: Int
    let backlinkCount: Int
    let followingCount: Int
}

struct UserProfile: Equatable {
    let petname: Petname
    let pfp: Image
    let bio: String
    
    let statistics: UserProfileStatistics
}

// TODO: stubbed type, use real data
struct Article: Equatable {
    let id: UUID
    let title: String
    let slug: String
    let datePublished: Date
}

struct UserProfileDetailModel: ModelProtocol {
    typealias Action = UserProfileDetailAction
    typealias Environment = AppEnvironment
    
    var user: UserProfile = UserProfile(
        petname: Petname("ben")!,
        pfp: Image("pfp-dog"),
        bio: "Henlo world.",
        statistics: UserProfileStatistics(
            noteCount: 123,
            backlinkCount: 64,
            followingCount: 19
        )
    )
    
    var articles: [Article] = [
        Article(id: UUID(), title: "Article 1", slug: "/article-1", datePublished: Date()),
        Article(id: UUID(), title: "Article 2", slug: "/article-2", datePublished: Date().addingTimeInterval(-86400)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
        Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800))
    ]

    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        Update(state: state)
    }
}
