//
//  DummyDataUtilities.swift
//  Subconscious
//
//  Created by Ben Follington on 31/3/2023.
//

import Foundation

protocol DummyData {
    static func dummyData() -> Self
}

extension Bool: DummyData {
    static func dummyData() -> Bool {
        random()
    }
}

extension Did: DummyData {
    static func dummyData() -> Did {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = String((0..<32).map{ _ in letters.randomElement()! })
        return Did(did: "did:key:\(randomString)")! // OK to do this for test data
    }
}

extension Petname: DummyData {
    static func dummyData() -> Petname {
        let letters = "abcdefghijklmnopqrstuvwxyz-_0123456789"
        let randomString = String((0..<8).map{ _ in letters.randomElement()! })
        return Petname(randomString)! // OK to do this for test data
    }
}

extension StoryUser: DummyData {
    static func dummyData() -> StoryUser {
        StoryUser(
            user: UserProfile(
                did: Did.dummyData(),
                petname: Petname.dummyData(),
                pfp: "pfp-dog",
                bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                category: [UserCategory.human, UserCategory.geist].randomElement()!
            ),
            following: Bool.dummyData()
        )
    }
}

