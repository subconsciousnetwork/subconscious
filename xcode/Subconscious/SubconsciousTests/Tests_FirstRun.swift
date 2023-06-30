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
            action: .submitFirstRunWelcomeStep,
            environment: AppEnvironment()
        )
        
        XCTAssertNil(up1.state.inviteCode)
        XCTAssertNil(up1.state.gatewayId)
        XCTAssertEqual(
            up1.state.firstRunPath,
            [.profile],
            "proceed in offline mode by default"
        )
        
        let up2 = AppModel.update(
            state: model,
            actions: [
                .requestOfflineMode
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertNil(up2.state.inviteCode)
        XCTAssertNil(up2.state.gatewayId)
        XCTAssertEqual(
            up2.state.firstRunPath,
            [.profile],
            "proceed if the user requests offline mode"
        )
        
        let up3 = AppModel.update(
            state: model,
            actions: [
                .inviteCodeFormField(.setValue(input: "one two three four")),
                .submitInviteCodeForm,
                .requestOfflineMode
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertNil(up3.state.inviteCode)
        XCTAssertNil(up3.state.gatewayId)
        XCTAssertEqual(
            up3.state.firstRunPath,
            [.profile],
            "proceed if the user requests offline mode after using form"
        )
        
        let up4 = AppModel.update(
            state: model,
            actions: [
                .inviteCodeFormField(.setValue(input: "one two three four")),
                .submitInviteCodeForm,
                .submitFirstRunWelcomeStep
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up4.state.inviteCode, InviteCode("one two three four")!)
        XCTAssertNil(up4.state.gatewayId)
        XCTAssertEqual(
            up4.state.firstRunPath,
            [],
            "cannot proceed with invite code but no gateway ID"
        )
        
        let up5 = AppModel.update(
            state: model,
            actions: [
                .inviteCodeFormField(.setValue(input: "one two three four")),
                .submitInviteCodeForm,
                .succeedRedeemInviteCode("my-gateway"),
                .submitFirstRunWelcomeStep
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(
            up5.state.firstRunPath,
            [.profile],
            "proceed with invite code + gateway ID"
        )
        XCTAssertEqual(up5.state.inviteCode, InviteCode("one two three four")!)
        XCTAssertEqual(up5.state.gatewayId, "my-gateway")
        XCTAssertTrue(up5.state.gatewayProvisioningStatus == .pending)
        
        let up6 = AppModel.update(
            state: model,
            actions: [
                .inviteCodeFormField(.setValue(input: "one two three four")),
                .submitInviteCodeForm,
                .succeedRedeemInviteCode("my-gateway"),
                .requestOfflineMode,
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(
            up6.state.firstRunPath,
            [.profile],
            "clear invite code + gateway ID when requesting offline"
        )
        XCTAssertNil(up6.state.inviteCode)
        XCTAssertNil(up6.state.gatewayId)
        
        // We should CANCEL the provisioniong process when offline mode is requested
        // ...but we can't do that until we add support for store-driven cancellation
        // XCTAssertTrue(up6.state.gatewayProvisioningStatus == .initial)
    }
    
    func testFirstRunProfileStep() throws {
        let model = AppModel(firstRunPath: [.profile])
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunProfileStep,
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up1.state.firstRunPath, [.profile], "cannot advance without a nickname")
        
        let up2 = AppModel.update(
            state: model,
            actions: [
                .nicknameFormField(.setValue(input: "my-name")),
                .submitFirstRunProfileStep
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up2.state.firstRunPath, [.profile, .sphere], "proceed with valid nickname")
        
        let up3 = AppModel.update(
            state: model,
            actions: [
                .nicknameFormField(.setValue(input: "My Crazy Name!")),
                .submitFirstRunProfileStep
            ],
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up3.state.firstRunPath, [.profile], "cannot proceed with invalid nickname")
    }
    
    func testFirstRunSphereStep() throws {
        let model = AppModel(firstRunPath: [.profile, .sphere])
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunSphereStep,
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up1.state.firstRunPath, [.profile, .sphere, .recovery], "proceed to recovery")
    }
    
    func testFirstRunRecoveryStep() throws {
        let model = AppModel(firstRunPath: [.profile, .sphere, .recovery])
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunRecoveryStep,
            environment: AppEnvironment()
        )
        
        XCTAssertEqual(up1.state.firstRunPath, [.profile, .sphere, .recovery, .done], "proceed to connect")
    }
    
    func testFirstRunConnectStep() throws {
        let model = AppModel(firstRunPath: [.profile, .sphere, .recovery, .done])
        let up1 = AppModel.update(
            state: model,
            action: .submitFirstRunDoneStep,
            environment: AppEnvironment()
        )
        
        // Assert fields are reset
        XCTAssertFalse(up1.state.nicknameFormField.touched)
        XCTAssertFalse(up1.state.inviteCodeFormField.touched)
        
        XCTAssertTrue(up1.state.isFirstRunComplete)
    }
}
