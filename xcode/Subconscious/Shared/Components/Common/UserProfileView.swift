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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack(alignment: .leading) {
                        HStack(spacing: AppTheme.unit3) {
                            
                            AsyncImage(url: URL(string: user.profilePicture), content: { image in
                                ProfilePic(image: image)
                            }, placeholder: {
                                ProgressView()
                            })
                            VStack(alignment: .leading, spacing: AppTheme.unit) {
                                Text(verbatim: "@\(user.petname)")
                                    .foregroundColor(.buttonText)
                                    .fontWeight(.semibold)
                                Text(verbatim: user.bio)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            Spacer()
                        }
                        
                        Spacer(minLength: AppTheme.padding*2)
                        
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Recent Activity")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                        VStack {
                            ForEach(user.recentArticles.prefix(3), id: \.id) { article in
                                Button(
                                    action: {},
                                    label: {
                                        Transclude2View(address: Slashlink(article.slug)!.toPublicMemoAddress(), excerpt: article.title, action: {})
                                    }
                                )
                            }
                            Button(action: {}, label: { Text("More...") })
                        }
                        
                        Spacer(minLength: AppTheme.padding*2)
                        
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Address Book")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                        VStack {
                            Button(action: {}, label: { AddressBookEntryView(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did("did:key:123")!) })
                            Button(action: {}, label: { AddressBookEntryView(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did("did:key:123")!) })
                            Button(action: {}, label: { AddressBookEntryView(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did("did:key:123")!) })
                            Button(action: {}, label: { Text("View All") })
                        }
                        
                        Spacer(minLength: AppTheme.padding * 3)
                    }
                    .padding(AppTheme.padding)
                    
                    //                    }
                    
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
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(user: User(id: UUID(),
                                   petname: "john-doe",
                                   bio: "SwiftUI developer and tech enthusiast.",
                                   profilePicture: "https://api.dicebear.com/6.x/shapes/png?seed=john-doe",
                                   recentArticles: [
                                    Article(id: UUID(), title: "Article 1", slug: "/article-1", datePublished: Date()),
                                    Article(id: UUID(), title: "Article 2", slug: "/article-2", datePublished: Date().addingTimeInterval(-86400)),
                                    Article(id: UUID(), title: "Article 3", slug: "/article-3", datePublished: Date().addingTimeInterval(-172800))
                                   ]))
    }
}
