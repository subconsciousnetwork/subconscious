//
//  StoryUserView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import SwiftUI

/// Show a user card in a feed format
struct StoryUserView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var story: StoryUser
    var action: (Slashlink) -> Void
    
    var profileAction: (UserProfile, UserProfileAction) -> Void = { _, _ in }
    var onRefreshUser: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unitHalf) {
            HStack(alignment: .center, spacing: 0) {
                Group {
                    HStack(spacing: AppTheme.unit2) {
                        ProfilePic(pfp: story.user.pfp, size: .medium)
                        
                        if let name = story.user.toNameVariant() {
                            PetnameView(name: name, aliases: story.user.aliases)
                        }
                    }
                    
                    Spacer()
                    
                    Group {
                        switch story.user.resolutionStatus {
                        case .unresolved:
                            Image(systemName: "person.fill.questionmark")
                                .foregroundColor(.secondary)
                        case .pending:
                            PendingSyncBadge()
                                .foregroundColor(.secondary)
                        case .resolved:
                            switch (story.user.ourFollowStatus, story.user.category) {
                            case (.following(_), _):
                                Image.from(appIcon: .following)
                                    .foregroundColor(.secondary)
                            case (_, .ourself):
                                Image.from(appIcon: .you(colorScheme))
                                    .foregroundColor(.secondary)
                            case (_, _):
                                EmptyView()
                            }
                        }
                    }
                    .frame(
                        width: AppTheme.minTouchSize,
                        height: AppTheme.minTouchSize,
                        alignment: .trailing // Creates correct spacing when next to "..."
                    )
                }
                .disabled(!story.user.resolutionStatus.isReady)
                
                Menu(
                    content: {
                        if story.user.isFollowedByUs {
                            Button(
                                action: {
                                    profileAction(story.user, .requestUnfollow)
                                },
                                label: {
                                    Label(
                                        title: { Text("Unfollow") },
                                        icon: { Image(systemName: "person.fill.xmark") }
                                    )
                                }
                            )
                            Button(
                                action: {
                                    profileAction(story.user, .requestRename)
                                },
                                label: {
                                    Label(
                                        title: { Text("Rename") },
                                        icon: { Image(systemName: "pencil") }
                                    )
                                }
                            )
                        } else {
                            Button(
                                action: {
                                    profileAction(story.user, .requestFollow)
                                },
                                label: {
                                    Label(
                                        title: { Text("Follow") },
                                        icon: { Image(systemName: "person.badge.plus") }
                                    )
                                }
                            )
                        }
                    },
                    label: {
                        EllipsisLabelView()
                    }
                ).disabled(story.user.category == .ourself)
            }
            // Omit trailing padding to allow ... hit target to move to top right corner
            .padding([.leading], AppTheme.padding)
            
            if let bio = story.user.bio,
               bio.hasVisibleContent {
                Text(verbatim: bio.text)
                    .padding([.leading, .trailing, .bottom], AppTheme.padding)
            }
        }
        .contentShape(.interaction, RectangleCroppedTopRightCorner())
        .onTapGesture {
            switch (story.user.ourFollowStatus, story.user.resolutionStatus) {
            case (.following(_), .unresolved):
                onRefreshUser()
            case (.following(let name), _):
                action(Slashlink(petname: name.toPetname()))
            case _:
                action(story.user.address)
            }
        }
        .background(.background)
    }
}

struct StoryUserView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Spacer()
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname.Name("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .human,
                        resolutionStatus: .unresolved,
                        ourFollowStatus: .notFollowing,
                        aliases: []
                    )
                ),
                action: { _ in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname.Name("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .human,
                        resolutionStatus: .pending,
                        ourFollowStatus: .following(Petname.Name("lol")!),
                        aliases: []
                    )
                ),
                action: { _ in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname.Name("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .ourself,
                        resolutionStatus: .resolved(Cid("ok")),
                        ourFollowStatus: .notFollowing,
                        aliases: []
                    )
                ),
                action: { _ in }
            )
            StoryUserView(
                story: StoryUser(
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname.Name("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio.empty,
                        category: .ourself,
                        resolutionStatus: .pending,
                        ourFollowStatus: .notFollowing,
                        aliases: []
                    )
                ),
                action: { _ in }
            )
            Spacer()
        }
        .background(.secondary)
        .frame(maxHeight: .infinity)
    }
}
