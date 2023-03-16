//
//  Tests_FormField.swift
//  SubconsciousTests
//
//  Created by Ben Follington on 15/3/2023.
//


import XCTest
import ObservableStore
@testable import Subconscious

class Tests_FormField: XCTestCase {
    static func validateStringIsHello(input: String) -> String? {
        if input == "hello" {
            return input
        }
        
        return nil
    }
    
    let environment = FormFieldEnvironment()
    
    func testDetectsFirstFocus() throws {
        let state = FormField(value: "", validate: Self.validateStringIsHello)
        let update = FormField.update(state: state, action: .focusChange(focused: true), environment: environment)
        
        XCTAssertEqual(
            update.state.hasBeenFocusedAtLeastOnce,
            true,
            "Tracks first focus correctly"
        )
        
        XCTAssertEqual(
            update.state.touched,
            false,
            "Does not set touched on initial focus"
        )
    }
    
    func testDetectsTouchedOnUnfocus() throws {
        let state = FormField(value: "", validate: Self.validateStringIsHello)
        var update = FormField.update(state: state, action: .focusChange(focused: true), environment: environment)
        update = FormField.update(state: update.state, action: .focusChange(focused: false), environment: environment)
        
        XCTAssertEqual(
            update.state.hasBeenFocusedAtLeastOnce,
            true,
            "Tracks first focus correctly"
        )
        
        XCTAssertEqual(
            update.state.touched,
            true,
            "Sets touched after focus then unfocus"
        )
    }
    
    func testOnlyDetectsTouchedAfterInitialFocus() throws {
        let state = FormField(value: "", validate: Self.validateStringIsHello)
        let update = FormField.update(state: state, action: .focusChange(focused: false), environment: environment)
        
        XCTAssertEqual(
            update.state.touched,
            false,
            "Does not set touched unless field has been focused once"
        )
    }
    
    func testMultipleInputUpdates() throws {
        let state = FormField(value: "DEFAULT", validate: Self.validateStringIsHello)
        
        var update = FormField.update(state: state, action: .setValue(input: "Zorpo"), environment: environment)
        
        XCTAssertEqual(update.state.value, "Zorpo", "Value is updated")
        
        update = FormField.update(state: update.state, action: .setValue(input: "Cronkulus"), environment: environment)
        
        XCTAssertEqual(update.state.value, "Cronkulus", "Value is updated")
    }
    
    func testResetField() throws {
        let state = FormField(value: "DEFAULT", validate: Self.validateStringIsHello)
        
        XCTAssertEqual(state.defaultValue, "DEFAULT", "Records default value")
        
        var update = FormField.update(state: state, action: .markAsTouched, environment: environment)
        
        XCTAssertEqual(update.state.touched, true, "Manually marked as touched")
        
        update = FormField.update(state: update.state, action: .setValue(input: "something else!"), environment: environment)
        
        XCTAssertEqual(update.state.defaultValue, "DEFAULT", "Preserves default value")
        XCTAssertEqual(update.state.value, "something else!", "Updates input value")
        
        update = FormField.update(state: update.state, action: .reset, environment: environment)
        
        XCTAssertEqual(update.state.value, state.defaultValue, "Resets input value")
        XCTAssertEqual(update.state.defaultValue, state.defaultValue, "Preserves default value")
        XCTAssertEqual(update.state.touched, state.touched, "Resets touched status")
    }
    
    func testValidation() throws {
        let state = FormField(value: "DEFAULT", validate: Self.validateStringIsHello)
        
        XCTAssertEqual(state.validated, nil, "Validated output is nil")
        XCTAssertEqual(state.isValid, false, "Validator fails")
        XCTAssertEqual(state.hasError, false, "No error is displayed")
        
        var update = FormField.update(state: state, action: .markAsTouched, environment: environment)
        
        XCTAssertEqual(update.state.validated, nil, "Validated output is nil")
        XCTAssertEqual(update.state.isValid, false, "Validator fails")
        XCTAssertEqual(update.state.hasError, true, "Error message is displayed")
        
        update = FormField.update(state: update.state, action: .setValue(input: "hello"), environment: environment)
        
        XCTAssertEqual(update.state.validated, "hello", "Validated output returned")
        XCTAssertEqual(update.state.isValid, true, "Validator passes")
        XCTAssertEqual(update.state.hasError, false, "No error message is displayed")
        
        update = FormField.update(state: update.state, action: .reset, environment: environment)
        
        XCTAssertEqual(state.validated, nil, "Validated output is nil")
        XCTAssertEqual(state.isValid, false, "Validator fails")
        XCTAssertEqual(state.hasError, false, "No error is displayed")
    }
}
