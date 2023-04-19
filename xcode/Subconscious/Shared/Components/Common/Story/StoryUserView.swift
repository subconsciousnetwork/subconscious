//
//  StoryUserView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

/// Show a user card in a feed format
struct StoryUserView: View {
    var story: StoryUser
    var action: (MemoAddress, String) -> Void
    
    var profileAction: (UserProfile, UserProfileAction) -> Void = { _, _ in }

    var body: some View {
        Button(
            action: {
                action(
                    Slashlink(petname: story.user.petname)
                        .toPublicMemoAddress(),
                    story.user.bio
                )
            }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.unit3) {
                HStack(alignment: .center, spacing: AppTheme.unit2) {
                    ProfilePicSm(image: Image(story.user.pfp))
                    
                    switch (story.user.category) {
                    case .human, .geist:
                        PetnameBylineView(petname: story.user.petname)
                    case .you:
                        PetnameBylineView(petname: story.user.petname)
                    }
                    
                    Spacer()
                    
                    switch (story.isFollowingUser, story.user.category) {
                    case (true, _):
                        AppIcon.following
                            .foregroundColor(.secondary)
                    case (_, .you):
                        AppIcon.you
                            .foregroundColor(.secondary)
                            .font(.callout)
                    case (_, _):
                        Spacer()
                    }
                }
                
                Text(verbatim: story.user.bio)
            }
            .padding()
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .background(Color.background)
    }
}

struct StoryUserView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        petname: Petname("ben.gordon.chris.bob")!,
                        pfp: "pfp-dog",
                        bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                        category: .human
                    ),
                    isFollowingUser: false
                ),
                action: { link, fallback in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        petname: Petname("ben.gordon.chris.bob")!,
                        pfp: "pfp-dog",
                        bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                        category: .human
                    ),
                    isFollowingUser: true
                ),
                action: { link, fallback in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        petname: Petname("ben.gordon.chris.bob")!,
                        pfp: "pfp-dog",
                        bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                        category: .you
                    ),
                    isFollowingUser: false
                ),
                action: { link, fallback in }
            )
        }
    }
}
