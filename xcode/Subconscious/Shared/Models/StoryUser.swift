//
//  StoryUser.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import Foundation
import SwiftUI

/// Story prompt model
struct StoryUser:
    Hashable,
    Identifiable,
    CustomStringConvertible,
    Codable
{
    var id = UUID()
    var user: UserProfile
    var following: Bool
    var statistics: UserProfileStatistics?

    var description: String {
        """
        \(String(describing: user.petname))
        Following? \(following)
        
        \(user.bio)
        """
    }
}

protocol Generatable {
    static func generateRandomTestInstance() -> Self
}

extension Bool: Generatable {
    static func generateRandomTestInstance() -> Bool {
        random()
    }
}

extension Did: Generatable {
    static func generateRandomTestInstance() -> Did {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = String((0..<32).map{ _ in letters.randomElement()! })
        return Did(did: "did:key:\(randomString)")! // OK to do this for test data
    }
}

extension Petname: Generatable {
    static func generateRandomTestInstance() -> Petname {
        let letters = "abcdefghijklmnopqrstuvwxyz-_0123456789"
        let randomString = String((0..<8).map{ _ in letters.randomElement()! })
        return Petname(randomString)! // OK to do this for test data
    }
}

extension StoryUser: Generatable {
    static func generateRandomTestInstance() -> StoryUser {
        StoryUser(
            user: UserProfile(
                did: Did.generateRandomTestInstance(),
                petname: Petname.generateRandomTestInstance(),
                pfp: "pfp-dog",
                bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber.",
                category: [UserCategory.human, UserCategory.geist].randomElement()!
            ),
            following: Bool.generateRandomTestInstance()
        )
    }
}

