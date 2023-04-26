//
//  Tests_App.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 3/27/23.
//

import XCTest
@testable import Subconscious

final class Tests_App: XCTestCase {
    func testPersistNoosphereEnabled() throws {
        let model = AppModel()
        let up1 = AppModel.update(
            state: model,
            action: .persistNoosphereEnabled(true),
            environment: AppEnvironment()
        )
        XCTAssertTrue(up1.state.isNoosphereEnabled, "isNoosphereEnabled set")
        let up2 = AppModel.update(
            state: model,
            action: .persistNoosphereEnabled(false),
            environment: AppEnvironment()
        )
        XCTAssertFalse(up2.state.isFirstRunComplete, "isNoosphereEnabled set")
    }
    
    func testPersistFirstRunComplete() throws {
        let model = AppModel()
        let up1 = AppModel.update(
            state: model,
            action: .persistFirstRunComplete(true),
            environment: AppEnvironment()
        )
        XCTAssertTrue(up1.state.isFirstRunComplete, "isFirstRunComplete set")
        let up2 = AppModel.update(
            state: model,
            action: .persistFirstRunComplete(false),
            environment: AppEnvironment()
        )
        XCTAssertFalse(up2.state.isFirstRunComplete, "isFirstRunComplete set")
    }
    
    func testNicknameFormField() throws {
        let model = AppModel()
        XCTAssertEqual(model.nicknameFormField.value, "", "Nickname form field is empty to start")
        XCTAssertEqual(model.nicknameFormField.isValid, false, "Nickname form field is not valid to start")
        XCTAssertEqual(model.nicknameFormFieldValue, "", "Nickname form field is empty to start")
        XCTAssertEqual(model.isNicknameFormFieldValid, false, "Nickname form field is not valid to start")

        let a = AppModel.update(
            state: model,
            action: .setNicknameFormFieldValue("!INVALID"),
            environment: AppEnvironment()
        )
        XCTAssertEqual(a.state.nicknameFormField.value, "!INVALID", "Nickname form field is set")
        XCTAssertEqual(a.state.nicknameFormField.isValid, false, "Nickname form field is not valid")
        XCTAssertEqual(a.state.nicknameFormFieldValue, "!INVALID", "Nickname form field value set")
        XCTAssertEqual(a.state.isNicknameFormFieldValid, false, "Nickname form field is not valid")
        XCTAssertEqual(a.state.nickname, "", "Nickname is not saved, because form field value is not valid")

        let b = AppModel.update(
            state: model,
            action: .setNicknameFormFieldValue("valid"),
            environment: AppEnvironment()
        )
        XCTAssertEqual(b.state.nicknameFormField.value, "valid", "Nickname form field is set")
        XCTAssertEqual(b.state.nicknameFormField.isValid, true, "Nickname form field is valid")
        XCTAssertEqual(b.state.nicknameFormFieldValue, "valid", "Nickname form field value set")
        XCTAssertEqual(b.state.isNicknameFormFieldValid, true, "Nickname form field is valid")
        XCTAssertEqual(b.state.nickname, "valid", "Nickname is saved, because form field value is valid")
    }
}
