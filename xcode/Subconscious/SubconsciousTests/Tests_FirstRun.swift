//
//  Tests_FirstRun.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 29/6/2023.
//

import XCTest
@testable import Subconscious

final class Tests_FirstRun: XCTestCase {
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
    
    func testFirstRunInviteCodeStep() throws {
        let model = AppModel()
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunStep(current: .initial),
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up1.state.firstRunPath, [.nickname], "proceed in offline mode by default")
        
        let up2 = AppModel.update(
            state: model,
            actions: [
                .requestOfflineMode
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up2.state.firstRunPath, [.nickname], "proceed if the user requests offline mode")
        
        let up3 = AppModel.update(
            state: model,
            actions: [
                .inviteCodeFormField(.setValue(input: "one two three four")),
                .submitInviteCodeForm,
                .requestOfflineMode
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up3.state.firstRunPath, [.nickname], "proceed if the user requests offline mode after using form")
        
        let up4 = AppModel.update(
            state: model,
            actions: [
                .inviteCodeFormField(.setValue(input: "one two three four")),
                .submitInviteCodeForm,
                .submitFirstRunStep(current: .initial)
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up4.state.firstRunPath, [], "cannot proceed with invite code but no gateway ID")
        
        let up5 = AppModel.update(
            state: model,
            actions: [
                .inviteCodeFormField(.setValue(input: "one two three four")),
                .submitInviteCodeForm,
                .succeedRedeemInviteCode("my-gateway"),
                .submitFirstRunStep(current: .initial)
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up5.state.firstRunPath, [.nickname],  "proceed with invite code + gateway ID")
        XCTAssertTrue(up5.state.gatewayProvisioningStatus == .pending)
    }
    
    func testFirstRunProfileStep() throws {
        let model = AppModel(firstRunPath: [.nickname])
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunStep(current: .nickname),
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up1.state.firstRunPath, [.nickname], "cannot advance without a nickname")
        
        let up2 = AppModel.update(
            state: model,
            actions: [
                .nicknameFormField(.setValue(input: "my-name")),
                .submitFirstRunStep(current: .nickname)
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up2.state.firstRunPath, [.nickname, .sphere], "proceed with valid nickname")
        
        let up3 = AppModel.update(
            state: model,
            actions: [
                .nicknameFormField(.setValue(input: "My Crazy Name!")),
                .submitFirstRunStep(current: .nickname)
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up3.state.firstRunPath, [.nickname], "cannot proceed with invalid nickname")
    }
    
    func testFirstRunSphereStep() throws {
        let model = AppModel(firstRunPath: [.nickname, .sphere])
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunStep(current: .sphere),
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up1.state.firstRunPath, [.nickname, .sphere, .recovery], "proceed to recovery")
    }
    
    func testFirstRunRecoveryStep() throws {
        let model = AppModel(firstRunPath: [.nickname, .sphere, .recovery])
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunStep(current: .recovery),
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up1.state.firstRunPath, [.nickname, .sphere, .recovery, .connect], "proceed to connect")
    }
    
    func testFirstRunConnectStep() throws {
        let model = AppModel(firstRunPath: [.nickname, .sphere, .recovery, .connect])
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunStep(current: .connect),
            environment: AppEnvironment()
        )
        
        // Assert fields are reset
        XCTAssertFalse(up1.state.nicknameFormField.touched)
        XCTAssertFalse(up1.state.inviteCodeFormField.touched)
        
        XCTAssertTrue(up1.state.isFirstRunComplete)
    }
}
