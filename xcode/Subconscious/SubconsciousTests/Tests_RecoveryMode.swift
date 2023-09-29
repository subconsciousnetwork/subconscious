//
//  Tests_RecoveryMode.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 9/29/23.
//

import XCTest
import Combine
@testable import Subconscious

final class Tests_RecoveryMode: XCTestCase {
    var cancellable: AnyCancellable?
    
    func testPressRecoverButtonAlreadySucceeded() throws {
        let environment = RecoveryModeModel.Environment()
        let state = RecoveryModeModel(
            recoveryStatus: .succeeded
        )
        let update = RecoveryModeModel.update(
            state: state,
            action: .pressRecoveryButton,
            environment: environment
        )
        XCTAssertEqual(
            state,
            update.state,
            "Pressing recover button when recovery has already succeeded does not change state"
        )
        
        let expectation = XCTestExpectation(
            description: "requestPresent is sent"
        )
        self.cancellable = update.fx.contains(.requestPresent(false)).sink(
            receiveCompletion: { completion in
                expectation.fulfill()
            },
            receiveValue: { isPresent in
                XCTAssertTrue(isPresent)
            }
        )
        wait(for: [expectation], timeout: 0.2)
    }
    
    func testPressRecoverButtonWithInvalidDid() throws {
        let environment = RecoveryModeModel.Environment()
        let state = RecoveryModeModel(
            recoveryStatus: .failed("Message"),
            recoveryDidField: RecoveryDidFormField(
                value: "!!! Not a DID !!!",
                validate: { value in Did(value)
                }
            )
        )
        let update = RecoveryModeModel.update(
            state: state,
            action: .pressRecoveryButton,
            environment: environment
        )
        XCTAssertEqual(
            state,
            update.state,
            "Pressing recover button when DID is invalid is a no-op"
        )
    }
    
    func testPressRecoverButtonWithInvalidGateway() throws {
        let environment = RecoveryModeModel.Environment()
        let state = RecoveryModeModel(
            recoveryStatus: .failed("Message"),
            recoveryGatewayURLField: GatewayUrlFormField(
                value: "!!! Not a gateway !!!",
                validate: { value in GatewayURL(value) }
            )
        )
        let update = RecoveryModeModel.update(
            state: state,
            action: .pressRecoveryButton,
            environment: environment
        )
        XCTAssertEqual(
            state,
            update.state,
            "Pressing recover button when gateway is invalid is a no-op"
        )
    }
    
    func testPressRecoverButtonWithInvalidRecoveryPhrase() throws {
        let environment = RecoveryModeModel.Environment()
        let state = RecoveryModeModel(
            recoveryStatus: .failed("Message"),
            recoveryPhraseField: RecoveryPhraseFormField(
                value: "!!! Not a recovery phrase !!!",
                validate: { value in RecoveryPhrase(value) }
            )
        )
        let update = RecoveryModeModel.update(
            state: state,
            action: .pressRecoveryButton,
            environment: environment
        )
        XCTAssertEqual(
            state,
            update.state,
            "Pressing recover button when recovery phrase is invalid is a no-op"
        )
    }
    
    func testPressRecoverButtonAllValid() throws {
        let environment = RecoveryModeModel.Environment()
        let state = RecoveryModeModel(
            recoveryStatus: .failed("Message"),
            recoveryPhraseField: RecoveryPhraseFormField(
                value: "foo bar baz bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom bim blap blap",
                validate: { value in RecoveryPhrase(value) }
            ),
            recoveryDidField: RecoveryDidFormField(
                value: "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                validate: { value in Did(value)
                }
            ),
            recoveryGatewayURLField: GatewayUrlFormField(
                value: "https://example.com",
                validate: { value in GatewayURL(value) }
            )
        )
        let update = RecoveryModeModel.update(
            state: state,
            action: .pressRecoveryButton,
            environment: environment
        )
        XCTAssertEqual(
            update.state.recoveryStatus,
            .pending,
            "Recovery is pending"
        )
    }
}
