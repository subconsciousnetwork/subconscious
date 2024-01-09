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

extension UserProfileBio: DummyData {
    static func dummyData() -> UserProfileBio {
        UserProfileBio(String.dummyDataMedium())
    }
}

extension Slug: DummyData {
    static func dummyData() -> Slug {
        Slug(String.dummyDataShort())!
    }
}

extension Petname.Name: DummyData {
    static func dummyData() -> Petname.Name {
        let options = [
            "mystic_mind",
            "dreamweaverz",
            "tarotwizdom",
            "psycheawaken",
            "enigmachine",
            "astralnavigatr",
            "magikalecho",
            "karmicwhisper",
            "spiritrealmer",
            "psychicmaze",
            "occultfusion",
            "mentalvoyage",
            "mysticforest",
            "soulscaper",
            "thoughtalchemy",
            "consciousflux",
            "astralpilgrim",
            "shadowgrimoire",
            "clairvoyantsea",
            "etherealstargaze",
            "transcendentpath",
            "arcane_insight",
            "soulcartographr",
            "realityshifter",
            "mindmirage",
            "enchantedportal",
            "cosmicintuition",
            "astraldreamer",
            "fateweaver",
            "spiritquester",
            "metaphysicalmage",
            "wisdomkeybearer"
        ]
        let randomString = options.randomElement()!
        return Petname.Name(randomString)! // OK to do this for test data
    }
}

extension Petname: DummyData {
    static func dummyData() -> Petname {
        Petname.Name.dummyData().toPetname()
    }
}

extension AddressBookEntry: DummyData {
    static func dummyData() -> AddressBookEntry {
        AddressBookEntry(
            petname: Petname.dummyData(),
            did: Did.dummyData(),
            status: .pending,
            version: Cid.dummyDataMedium()
        )
    }
}

extension StoryUser: DummyData {
    static func dummyData() -> StoryUser {
        return StoryUser(
            entry: AddressBookEntry.dummyData(),
            user: UserProfile.dummyData()
        )
    }
    
    static func dummyData(petname: Petname) -> StoryUser {
        StoryUser(
            entry: AddressBookEntry.dummyData(),
            user: UserProfile(
                did: Did.dummyData(),
                nickname: petname.leaf,
                address: Slashlink(petname: petname),
                pfp: .image(String.dummyProfilePicture()),
                bio: UserProfileBio.dummyData(),
                category: [UserCategory.human, UserCategory.geist].randomElement()!,
                ourFollowStatus: [
                    .following(Petname.Name.dummyData()),
                    .notFollowing
                ].randomElement()!,
                aliases: []
            )
        )
    }
}

extension String {
    static func dummyProfilePicture() -> String {
        let pfps = [
            "pfp-dog",
            "sub_logo"
        ]
        return pfps.randomElement()!
    }
    
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
    
    static func dummyDataLong() -> String {
        return """
               In a vast, labyrinthine mind, a young, vibrant idea named Lumo was born. Eager to be noticed, Lumo darted through the maze of thoughts, but soon found itself lost among ancient memories and towering concepts. Desperate, Lumo sought guidance from the wise old notions that resided in the quieter corners. They taught Lumo the art of patience and resilience. Days turned into weeks, yet Lumo's glow did not dim. Instead, it learned from each encounter, growing brighter and stronger. Finally, during a moment of serene clarity, Lumo emerged at the forefront of the thinker's mind, radiant and ready to change the world.
               """
    }
}

extension EntryStub: DummyData {
    static func dummyData() -> EntryStub {
        return dummyData(petname: Petname.dummyData())
    }
    
    static func dummyData(petname: Petname) -> EntryStub {
        let slashlink = Slashlink("@\(petname)/entry-\(Int.random(in: 0..<99))")!
        let address = slashlink
        let excerpt = Subtext(markup: String.dummyDataLong())
        let modified = Date().addingTimeInterval(TimeInterval(-86400 * Int.random(in: 0..<5)))
        
        return EntryStub(
            did: Did.dummyData(),
            address: address,
            excerpt: excerpt,
            modified: modified,
            headers: .emptySubtext
        )
    }
    
    static func dummyData(petname: Petname, slug: Slug) -> EntryStub {
        let slashlink = Slashlink(petname: petname, slug: slug)
        let address = slashlink
        let excerpt = Subtext(markup: String.dummyDataLong())
        let modified = Date().addingTimeInterval(TimeInterval(-86400 * Int.random(in: 0..<5)))
        
        return EntryStub(
            did: Did.dummyData(),
            address: address,
            excerpt: excerpt,
            modified: modified,
            headers: .emptySubtext
        )
    }
}

extension Memo: DummyData {
    static func dummyData() -> Memo {
        Memo(
            contentType: "text/subtext",
            created: Date.now,
            modified: Date.now,
            fileExtension: "subtext",
            color: NoteColor.allCases.randomElement(),
            additionalHeaders: Headers(),
            body: String.dummyDataMedium()
        )
    }
}

extension UserProfile: DummyData {
    static func dummyData() -> UserProfile {
        let nickname = Petname.Name.dummyData()
        return UserProfile(
            did: Did.dummyData(),
            nickname: nickname,
            address: Slashlink(petname: nickname.toPetname()),
            pfp: .image(String.dummyProfilePicture()),
            bio: UserProfileBio.dummyData(),
            category: .human,
            ourFollowStatus: .notFollowing,
            aliases: []
        )
    }
    
    static func dummyData(category: UserCategory) -> UserProfile {
        let nickname = Petname.Name.dummyData()
        return UserProfile(
            did: Did.dummyData(),
            nickname: nickname,
            address: category == .ourself
                ? Slashlink.ourProfile
                : Slashlink(petname: nickname.toPetname()),
            pfp: .image(String.dummyProfilePicture()),
            bio: UserProfileBio.dummyData(),
            category: category,
            ourFollowStatus: .notFollowing,
            aliases: []
        )
    }
}

extension UserProfileStatistics: DummyData {
    static func dummyData() -> UserProfileStatistics {
        UserProfileStatistics(
            noteCount: Int.random(in: 0..<999),
            backlinkCount: Int.random(in: 0..<999),
            followingCount: Int.random(in: 0..<99)
        )
    }
}
