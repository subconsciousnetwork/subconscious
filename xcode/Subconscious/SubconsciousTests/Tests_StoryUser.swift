//
//  Tests_StoryUser.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/19/23.
//

import XCTest
@testable import Subconscious

final class Tests_StoryUser: XCTestCase {
    func testDescription() throws {
        let story = StoryUser(
            entry: AddressBookEntry(
                petname: Petname(name: Petname.Name(formatting: "bob")!),
                did: Did("did:key:abc123")!,
                status: .unresolved,
                version: "bafyfakefakefake"
            ),
            user: UserProfile(
                did: Did("did:key:abc123")!,
                nickname: Petname.Name(formatting: "bob")!,
                address: Slashlink("@bob/foo")!,
                pfp: .generated(Did("did:key:abc123")!),
                bio: nil,
                category: .human,
                ourFollowStatus: .following(Petname.Name(formatting: "bob")!),
                aliases: []
            )
        )
        XCTAssertEqual(story.description, "StoryUser(did:key:abc123, @bob/foo, Optional(bob), following(bob))")
    }
}
