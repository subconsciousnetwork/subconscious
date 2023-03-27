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
                    VStack() {
                        AsyncImage(url: URL(string: user.profilePicture), content: { image in
                            image.resizable()
                        }, placeholder: {
                            ProgressView()
                        })
                        .frame(width: 128, height: 128)
                        .background(.background)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))

                        VStack(spacing: AppTheme.unit) {
                            Text(user.petname)
                                .font(.callout)
                                .foregroundColor(.buttonText)
                                .fontWeight(.semibold)

                            Text(user.bio)
                                .font(.callout)
                                .multilineTextAlignment(.leading)
                        }

                    }
                    .padding(AppTheme.padding)
                    .frame(maxWidth: .infinity)
                    //                .background(RadialGradient(stops: Color.brandDarkMarkGradient, center: .center, startRadius: 100, endRadius: 500))
                    .background(
                        AsyncImage(url: URL(string: user.profilePicture), content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 10)
                                .opacity(0.5)
                        }, placeholder: {
                            ProgressView()
                        })
                    )
                    .frame(maxHeight: 256)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "sparkles.rectangle.stack")
                            Text("Recent Activity")
                        }
                        .font(.callout)
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
                        
                        Spacer(minLength: AppTheme.padding*3)
                        //                    }
                        
                        //                    Section(
                        //                        header: HStack {
                        //                            Image(systemName: "person.2")
                        //                            Text("Address Book")
                        //                        }
                        //                            .foregroundColor(.buttonText)
                        //                            .fontWeight(.semibold)
                        //                    ) {
                        HStack {
                            Image(systemName: "person.2")
                            Text("Address Book")
                        }
                        .font(.callout)
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
                    .frame(maxWidth: .infinity)
                    .background(.white)
                    .cornerRadius(16, corners: .allCorners)
                    .shadow(color: .secondary.opacity(0.5), radius: 10, x: 0, y: 0)
                    
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
