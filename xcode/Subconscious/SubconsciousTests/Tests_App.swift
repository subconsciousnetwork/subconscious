//
//  Tests_App.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/27/23.
//

import XCTest
@testable import Subconscious

final class Tests_App: XCTestCase {
    func testNicknameFormField() throws {
        let model = AppModel()
        XCTAssertEqual(model.nicknameFormField.value, "", "Nickname form field is empty to start")
        XCTAssertEqual(model.nicknameFormField.isValid, false, "Nickname form field is not valid to start")
        
        let a = AppModel.update(
            state: model,
            action: .setNickname("!INVALID"),
            environment: AppEnvironment()
        )
        XCTAssertEqual(a.state.nicknameFormField.value, "!INVALID", "Nickname form field is set")
        XCTAssertEqual(a.state.nicknameFormField.isValid, false, "Nickname form field is not valid")
        XCTAssertEqual(a.state.nickname, "", "Nickname is not saved, because form field value is not valid")
        
        let b = AppModel.update(
            state: model,
            action: .setNickname("valid"),
            environment: AppEnvironment()
        )
        XCTAssertEqual(b.state.nicknameFormField.value, "valid", "Nickname form field is set")
        XCTAssertEqual(b.state.nicknameFormField.isValid, true, "Nickname form field is valid")
        
        let c = AppModel.update(state: model, action: .submitNickname(Petname.Name("valid")!), environment: AppEnvironment())
        XCTAssertEqual(c.state.nickname, "valid", "Nickname is saved after submitted valid nickname.")
    }
}
