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
    var onNavigate: () -> Void
    
    var profileAction: (UserProfile, UserProfileAction) -> Void = { _, _ in }
    var onRefreshUser: () -> Void = {}
    
    var entry: AddressBookEntry {
        story.entry
    }
    var user: UserProfile {
        story.user
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(alignment: .leading, spacing: AppTheme.unit2) {
                HStack(alignment: .center, spacing: AppTheme.unit2) {
                    Group {
                        ProfilePic(pfp: user.pfp, size: .large)
                        
                        if let name = user.toNameVariant() {
                            PetnameView(name: name, aliases: user.aliases)
                        }
                        
                        Spacer()
                        
                        switch entry.status {
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
                    .disabled(!story.entry.status.isReady)
                    
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
            }
            
            if let bio = user.bio,
               bio.hasVisibleContent {
                Text(verbatim: bio.text)
                    .padding(AppTheme.tightPadding)
            }
        }
        .contentShape(.interaction, RectangleCroppedTopRightCorner())
        .onTapGesture {
            switch (user.ourFollowStatus, entry.status) {
            case (.following(_), .unresolved):
                onRefreshUser()
            default:
                onNavigate()
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
                    entry: AddressBookEntry(
                        petname: Petname("ben")!,
                        did: Did("did:key:123")!,
                        status: .resolved("ok"),
                        version: "ok"
                    ),
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname.Name("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .human,
                        ourFollowStatus: .notFollowing,
                        aliases: []
                    )
                ),
                onNavigate: { }
            )
            StoryUserView(
                story: StoryUser(
                    entry: AddressBookEntry(
                        petname: Petname("ben")!,
                        did: Did("did:key:123")!,
                        status: .resolved("ok"),
                        version: "ok"
                    ),
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname.Name("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .human,
                        ourFollowStatus: .following(Petname.Name("lol")!),
                        aliases: []
                    )
                ),
                onNavigate: { }
            )
            StoryUserView(
                story: StoryUser(
                    entry: AddressBookEntry(
                        petname: Petname("ben")!,
                        did: Did("did:key:123")!,
                        status: .resolved("ok"),
                        version: "ok"
                    ),
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname.Name("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio("Ploofy snooflewhumps burbled, outflonking the zibber-zabber."),
                        category: .ourself,
                        ourFollowStatus: .notFollowing,
                        aliases: []
                    )
                ),
                onNavigate: { }
            )
            StoryUserView(
                story: StoryUser(
                    entry: AddressBookEntry(
                        petname: Petname("ben")!,
                        did: Did("did:key:123")!,
                        status: .resolved("ok"),
                        version: "ok"
                    ),
                    user: UserProfile(
                        did: Did("did:key:123")!,
                        nickname: Petname.Name("ben")!,
                        address: Slashlink(petname: Petname("ben.gordon.chris.bob")!),
                        pfp: .image("pfp-dog"),
                        bio: UserProfileBio.empty,
                        category: .ourself,
                        ourFollowStatus: .notFollowing,
                        aliases: []
                    )
                ),
                onNavigate: { }
            )
            Spacer()
        }
        .background(.background)
        .frame(maxHeight: .infinity)
    }
}
