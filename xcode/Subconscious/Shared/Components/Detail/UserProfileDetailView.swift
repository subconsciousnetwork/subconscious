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
            statistics: store.state.statistics,
            entries: store.state.articles,
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

struct UserProfileStatistics: Equatable, Codable, Hashable {
    let noteCount: Int
    let backlinkCount: Int
    let followingCount: Int
}

struct UserProfile: Equatable, Codable, Hashable {
    let petname: Petname
    let pfp: String
    let bio: String
}

struct UserProfileDetailModel: ModelProtocol {
    typealias Action = UserProfileDetailAction
    typealias Environment = AppEnvironment
    
    var user: UserProfile = UserProfile(
        petname: Petname("ben")!,
        pfp: "pfp-dog",
        bio: "Henlo world."
    )
    
    var statistics: UserProfileStatistics = UserProfileStatistics(
        noteCount: 123,
        backlinkCount: 64,
        followingCount: 19
    )
    
    
    var articles: [EntryStub] = generateEntryStubs(petname: "ben", count: 10)

    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        Update(state: state)
    }
    
    static func generateEntryStubs(petname: String, count: Int) -> [EntryStub] {
        let excerpts = [
            "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle. Snufflewumpus, indeed!",
            "Quibbling frizznips flabbled with snerkling snarklewinks, creating a glorptastic kerfuffle.",
            "Frobbly zingledorp spluttered, \"Wibbly-wabbly zorptang, snigglefritz me dooflebop!\" Skrinkle-plonk went the sploofinator, gorfing jibberjabberly amidst the blibber-blabber..",
        ]
        
        return (1...count).map { index in
            let slashlink = Slashlink("@\(petname)/article-\(index)")!
            let address = slashlink.toPublicMemoAddress()
            let excerpt = excerpts[index % excerpts.count]
            let modified = Date().addingTimeInterval(TimeInterval(-86400 * index))
            
            return EntryStub(address: address, excerpt: excerpt, modified: modified)
        }
    }
}
