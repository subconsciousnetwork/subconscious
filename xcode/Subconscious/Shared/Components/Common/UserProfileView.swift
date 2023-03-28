//
//  UserProfileView.swift
//  Subconscious
//
//  Created by Ben Follington on 27/3/2023.
//

import Foundation
import SwiftUI

struct User {
    let id: UUID
    let notes: Int
    let backlinks: Int
    let following: Int
    let petname: String
    let bio: String
    let profilePicture: String
    let recentArticles: [Article]
}

struct Article {
    let id: UUID
    let title: String
    let slug: String
    let datePublished: Date
}

struct UserProfileView: View {
    let user: User
    @State var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading) {
                    HStack(alignment: .top, spacing: AppTheme.unit3) {
                        
                        AsyncImage(url: URL(string: user.profilePicture), content: { image in
                            ProfilePic(image: image)
                        }, placeholder: {
                            ProgressView()
                        })
                        VStack(alignment: .leading, spacing: AppTheme.unit) {
                            PetnameBylineView(rawString: user.petname)
                            Text(verbatim: user.bio)
                            
                            HStack(spacing: AppTheme.unit2) {
                                HStack(spacing: AppTheme.unit) {
                                    Text("\(user.notes)").bold()
                                    Text("Notes").foregroundColor(.secondary)
                                }
                                HStack(spacing: AppTheme.unit) {
                                    Text("\(user.backlinks)").bold()
                                    Text("Backlinks").foregroundColor(.secondary)
                                }
                                HStack(spacing: AppTheme.unit) {
                                    Text("\(user.following)").bold()
                                    Text("Following").foregroundColor(.secondary)
                                }
                            }
                            .padding([.top], AppTheme.unit2)
                            .font(.caption)
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(AppTheme.padding)
                    
                    TabHeaderView(
                        items: [
                            TabViewItem(label: "Recent", action: {}),
                            TabViewItem(label: "Top", action: {}),
                            TabViewItem(label: "Following", action: {}),
                        ],
                        tabChanged: { index, tab in selectedTab = index },
                        focusedTabIndex: selectedTab
                    )
                        
                }
                
                MultiColumnView(
                    user: user,
                    focusedColumnIndex: selectedTab,
                    columns: [
                        AnyView(Group {
                            //TODO: note card component
                            ForEach(user.recentArticles, id: \.id) { article in
                                Button(
                                    action: {},
                                    label: {
                                        Transclude2View(address: Slashlink(article.slug)!.toPublicMemoAddress(), excerpt: article.title, action: {})
                                    }
                                )
                            }
                            Button(action: {}, label: { Text("More...") })
                        }),
                        AnyView(Group {
                            //TODO: note card component
                            ForEach(user.recentArticles, id: \.id) { article in
                                Button(
                                    action: {},
                                    label: {
                                        Transclude2View(address: Slashlink(article.slug)!.toPublicMemoAddress(), excerpt: article.title, action: {})
                                    }
                                )
                            }
                            Button(action: {}, label: { Text("More...") })
                        }),
                        AnyView(Group {
                            //TODO: user card component
                            ForEach(0..<30) {_ in
                                Button(action: {}, label: { AddressBookEntryView(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did("did:key:123")!) })
                            }
                            
                            Button(action: {}, label: { Text("View All") })
                        })
                    ]
                )
            }
        }
        .navigationTitle(user.petname)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            DetailToolbarContent(
                address: Slashlink("@\(user.petname)/profile")!.toPublicMemoAddress(),
                defaultAudience: .public,
                onTapOmnibox: {
                    
                }
            )
        })
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(user: User(id: UUID(),
                                   notes: 123,
                                   backlinks: 64,
                                   following: 19,
                                   petname: "john-doe",
                                   bio: "SwiftUI developer and tech enthusiast.",
                                   profilePicture: "https://api.dicebear.com/6.x/shapes/png?seed=john-doe",
                                   recentArticles: [
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
                                    Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800)),
                                   ]))
    }
}
