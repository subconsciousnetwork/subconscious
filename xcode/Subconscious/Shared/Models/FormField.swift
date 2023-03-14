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

enum FormFieldAction<Input: Equatable> {
    case reset
    /// Intended for triggering validation errors when a user submits a form containing this field
    case markAsTouched
    case focusChange(focused: Bool)
    case setValue(input: Input)
}

struct FormFieldEnvironment {}

struct FormField<Input: Equatable, Output>: Equatable, ModelProtocol {
    static func == (lhs: FormField<Input, Output>, rhs: FormField<Input, Output>) -> Bool {
        return (
            lhs.value == rhs.value &&
            lhs.touched == rhs.touched &&
            lhs.isValid == rhs.isValid &&
            lhs.hasBeenFocusedAtLeastOnce == rhs.hasBeenFocusedAtLeastOnce
        )
    }
    
    var value: Input
    var defaultValue: Input
    /// Should be a pure, static function
    var validate: FormFieldValidator<Input, Output>
    var touched: Bool
    var hasBeenFocusedAtLeastOnce: Bool
    
    init(value: Input, defaultValue: Input, validate: @escaping FormFieldValidator<Input, Output>) {
        self.value = value
        self.defaultValue = defaultValue
        self.validate = validate
        self.touched = false
        self.hasBeenFocusedAtLeastOnce = false
    }
    
    init(value: Input, validate: @escaping FormFieldValidator<Input, Output>) {
        self.value = value
        self.defaultValue = value
        self.validate = validate
        self.touched = false
        self.hasBeenFocusedAtLeastOnce = false
    }
    
    /// Attempt to validate the input and produce the backing type
    var validated: Output? {
        get {
            validate(value)
        }
    }
    /// Is the current value valid?
    var isValid: Bool {
        get {
            validated != nil
        }
    }
    /// Should this field visually display an error?
    var hasError: Bool {
        get {
            !isValid && touched
        }
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
            return Update(state: model)
            
        case .focusChange(let focused):
            var model = state
            // Only mark as touched when the field loses focus after an initial input.
            // This avoids telling the user that a field is invalid before they've even typed in it.
            if state.hasBeenFocusedAtLeastOnce && !focused {
                model.touched = true
            }
            
            if focused {
                model.hasBeenFocusedAtLeastOnce = true
            }
            return Update(state: model)
            
        case .markAsTouched:
            var model = state
            model.hasBeenFocusedAtLeastOnce = true
            model.touched = true
            return Update(state: model)
            
        case .setValue(input: let input):
            var model = state
            model.value = input
            return Update(state: model)
        }
    }
}
