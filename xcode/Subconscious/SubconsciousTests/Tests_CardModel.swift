//
//  Tests_CardModel.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 5/1/2024.
//

import XCTest
@testable import Subconscious

final class Tests_CardModel: XCTestCase {
    func testUpdateEntry() throws {
        let first = EntryStub.dummyData()
        let card = CardModel(
            card: .entry(
                entry: first,
                author: UserProfile.dummyData(),
                related: []
            ),
            liked: false
        )
        
        let second = EntryStub.dummyData()
        let updated = card.update(entry: second, liked: true)
        
        XCTAssert(updated.entry == second)
        XCTAssert(updated.liked == true)
    }
    
    func testUpdatePrompt() throws {
        let first = EntryStub.dummyData()
        let card = CardModel(
            card: .prompt(
                message: "lol",
                entry: first,
                author: UserProfile.dummyData(),
                related: []
            ),
            liked: true
        )
        
        let second = EntryStub.dummyData()
        let updated = card.update(entry: second, liked: false)
        
        XCTAssert(updated.entry == second)
        XCTAssert(updated.liked == false)
    }
}
