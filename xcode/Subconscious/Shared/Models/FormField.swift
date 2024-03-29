//
//  FormField.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 11/3/2023.
//

import os
import Foundation
import SwiftUI
import ObservableStore
import Combine

typealias FormFieldValidator<Input, Output> = (Input) -> Output?

typealias FormFieldInput = Equatable & Hashable

enum FormFieldAction<Input: FormFieldInput>:
    FormFieldInput,
    CustomStringConvertible
{
    case reset
    /// Intended for triggering validation errors when a user submits a form containing this field
    case markAsTouched
    case focusChange(focused: Bool)
    case setValue(input: Input)
    case setValidationStatus(valid: Bool)

    var description: String {
        switch self {
        case .reset:
            return "reset"
        case .markAsTouched:
            return "markAsTouched"
        case .focusChange(let focused):
            return "focusChange(\(focused)"
        case .setValue:
            return "setValue(--redacted--)"
        case .setValidationStatus(let valid):
            return "setValidationStatus(\(valid)"
        }
    }
}

typealias FormFieldEnvironment = Void

struct FormField<Input: FormFieldInput, Output>: ModelProtocol {
    static func == (lhs: FormField<Input, Output>, rhs: FormField<Input, Output>) -> Bool {
        return (
            lhs.value == rhs.value &&
            lhs.defaultValue == rhs.defaultValue &&
            lhs.isValid == rhs.isValid &&
            lhs.touched == rhs.touched &&
            lhs.hasFocus == rhs.hasFocus &&
            lhs.hasBeenFocusedAtLeastOnce == rhs.hasBeenFocusedAtLeastOnce
        )
    }
    
    @Redacted var value: Input
    var defaultValue: Input
    /// Should be a pure, static function
    var validate: FormFieldValidator<Input, Output>
    var isValid: Bool = false
    var touched: Bool
    var hasFocus: Bool
    var hasBeenFocusedAtLeastOnce: Bool
    
    init(value: Input, defaultValue: Input, validate: @escaping FormFieldValidator<Input, Output>) {
        self.value = value
        self.defaultValue = defaultValue
        self.validate = validate
        self.touched = false
        self.hasFocus = false
        self.hasBeenFocusedAtLeastOnce = false
        self.isValid = false
    }
    
    init(value: Input, validate: @escaping FormFieldValidator<Input, Output>) {
        self.value = value
        self.defaultValue = value
        self.validate = validate
        self.touched = false
        self.hasFocus = false
        self.hasBeenFocusedAtLeastOnce = false
        self.isValid = false
    }
    
    /// Attempt to validate the input and produce the backing type
    var validated: Output? {
        validate(value)
    }
    
    /// Should this field visually display an error?
    var shouldPresentAsInvalid: Bool {
        !isValid && hasBeenFocusedAtLeastOnce
    }
    
    static func update(
        state: Self,
        action: FormFieldAction<Input>,
        environment: FormFieldEnvironment
    ) -> Update<Self> {
        switch action {
        case .reset:
            var model = state
            model.touched = false
            model.value = state.defaultValue
            model.hasBeenFocusedAtLeastOnce = false
            return Update(state: model).animation(.easeOutCubic())
            
        case .focusChange(let focused):
            var model = state
            model.hasFocus = focused
            
            // Only mark as touched when the field loses focus after an initial input.
            // This avoids telling the user that a field is invalid before they've even typed in it.
            if state.hasBeenFocusedAtLeastOnce && !focused {
                model.touched = true
            }
            
            if focused {
                model.hasBeenFocusedAtLeastOnce = true
            }
            return Update(state: model).animation(.easeOutCubic())
            
        case .markAsTouched:
            var model = state
            model.hasBeenFocusedAtLeastOnce = true
            model.touched = true
            return Update(state: model).animation(.easeOutCubic())
            
        case .setValue(input: let input):
            var model = state
            model.value = input
            model.isValid = state.validate(input) != nil
            return Update(state: model).animation(.easeOutCubic())
            
        case .setValidationStatus(let valid):
            var model = state
            model.isValid = valid
            return Update(state: model).animation(.easeOutCubic())
        }
    }
}
