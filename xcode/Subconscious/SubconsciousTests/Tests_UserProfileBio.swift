//
//  Tests_UserProfileBio.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 17/5/2023.
//

import XCTest
@testable import Subconscious
@testable import SubconsciousCore

class Tests_UserProfileBio: XCTestCase {
    func testUnchanged() throws {
        let bio = "This is a nice bio."
        XCTAssertEqual(bio, UserProfileBio(bio).text)
    }
    
    func testUnicode() throws {
        let bio = "🧠🤝🤖豈 更 車ぁ あ ぃ✁ ✂ ✃☀ ☁ ☂ก ข ฃ"
        
        XCTAssertEqual(bio, UserProfileBio(bio).text)
    }
    
    func testWhitespace() throws {
        let bio = """
                  This            is a
        nice bio.
        """
        
        XCTAssertEqual("This is a nice bio.", UserProfileBio(bio).text)
    }
    
    func testAppliedInProfileEditor() {
        let state = EditProfileSheetModel()
        let valid = "hello world"
        let tooLong = """
                      I arose at precisely 7:32 AM and embarked on my morning ritual. \
                      In my quaint kitchen, I prepared a breakfast of champions. \
                      I began with two perfectly toasted slices of golden brown sourdough \
                      bread, each grain visible. Upon them, I delicately spread a \
                      layer of creamy, organic butter.
                      """
        
        let a = state.bioField.validate(valid)
        XCTAssertNotNil(a)
        XCTAssertEqual(a!.text, valid)
        
        let b = state.bioField.validate(tooLong)
        XCTAssertNotNil(b)
        XCTAssertEqual(b!.text.count, 280)
    }
    
    func testTruncation() throws {
        let bio = """
                  I arose at precisely 7:32 AM and embarked on my morning ritual. \
                  In my quaint kitchen, I prepared a breakfast of champions. \
                  I began with two perfectly toasted slices of golden brown sourdough \
                  bread, each grain visible. Upon them, I delicately spread a \
                  layer of creamy, organic butter.
                  """
        
        let expected = """
                  I arose at precisely 7:32 AM and embarked on my morning ritual. \
                  In my quaint kitchen, I prepared a breakfast of champions. \
                  I began with two perfectly toasted slices of golden brown sourdough \
                  bread, each grain visible. Upon them, I delicately spread a \
                  layer of creamy, organic butt
                  """
        
        XCTAssertEqual(expected, UserProfileBio(bio).text)
    }
}
