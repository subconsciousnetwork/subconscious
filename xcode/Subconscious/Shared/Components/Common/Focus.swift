//
//  Focus.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/2/22.
//

import Foundation
import ObservableStore

//  MARK: Action
enum FocusAction<Focus>: Hashable
where Focus: Hashable
{
    /// Request a model-driven focus change
    case requestFocus(Focus?)
    /// Focus change request scheduled
    case focusChangeScheduled
    /// Focus change from the UI. UI-driven focus always wins.
    case focusChange(Focus?)
}

//  MARK: Model
/// FocusModel contains state for managing focus.
/// UIKit has a number of APIs that require asyncronous focus change.
/// This keeps state for tracking current focus, requested focus, and focus
/// change scheduling.
struct FocusModel<Focus>: Hashable
where Focus: Hashable
{
    typealias Model = Self
    typealias Action = FocusAction<Focus>

    /// Dirty flag indicating whether a refocus has been scheduled
    var isScheduled = false
    /// Desired focus
    var focusRequest: Focus?
    /// Actual focus
    var focus: Focus?

    var isDirty: Bool {
        focusRequest != focus
    }

    /// Read if a given focus request state is related to a field.
    /// - True means "focus me"
    /// - False means "unfocus me"
    /// - Nil means "state is unrelated to me"
    func readFocusRequestFor(field: Focus) -> Bool? {
        if focusRequest == field {
            return true
        } else if focus == field && focusRequest == nil {
            return false
        }
        return nil
    }

    //  MARK: Update
    static func update(
        state: Model,
        action: Action,
        environment: Void
    ) -> Update<Model, Action> {
        switch action {
        case .requestFocus(let focus):
            var model = state
            model.isScheduled = false
            model.focusRequest = focus
            return Update(state: model)
        case .focusChangeScheduled:
            var model = state
            model.isScheduled = true
            return Update(state: model)
        case .focusChange(let focus):
            var model = state
            // UI-driven focus changes always wins.
            // - Toggle off any focus change request
            // - Set desired focus to this focus
            model.isScheduled = false
            model.focusRequest = focus
            model.focus = focus
            return Update(state: model)
        }
    }
}
