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

extension String {
    static func dummyDataShort() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz-_0123456789"
        return String((0..<12).map{ _ in letters.randomElement()! })
    }
    
    static func dummyDataMedium() -> String {
        let excerpts = [
            "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle. Snufflewumpus, indeed!",
            "Quibbling frizznips flabbled with snerkling snarklewinks, creating a glorptastic kerfuffle.",
            "Frobbly zingledorp spluttered, \"Wibbly-wabbly zorptang, snigglefritz me dooflebop!\" Skrinkle-plonk went the sploofinator, gorfing jibberjabberly amidst the blibber-blabber..",
        ]
        
        return excerpts.randomElement()!
    }
}

extension EntryStub: DummyData {
    static func dummyData() -> EntryStub {
        let slashlink = Slashlink("@\(Petname.dummyData())/article-\(Int.random(in: 0..<99))")!
        let address = slashlink.toPublicMemoAddress()
        let excerpt = String.dummyDataMedium()
        let modified = Date().addingTimeInterval(TimeInterval(-86400 * Int.random(in: 0..<5)))
        
        return EntryStub(address: address, excerpt: excerpt, modified: modified)
    }
}
