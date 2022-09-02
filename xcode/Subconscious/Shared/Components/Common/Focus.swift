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
    case focusRequestScheduled
    /// Focus change from the UI. UI-driven focus always wins.
    case focusChange(Focus?)
}

//  MARK: Model
struct FocusModel<Focus>: Hashable
where Focus: Hashable
{
    typealias Model = Self
    typealias Action = FocusAction<Focus>

    /// Dirty flag indicating whether a refocus has been scheduled
    var focusRequestScheduled = false
    /// Desired focus
    var focusRequest: Focus?
    /// Actual focus
    var focus: Focus?

    //  MARK: Update
    static func update(
        state: Model,
        action: Action,
        environment: Void
    ) -> Update<Model, Action> {
        switch action {
        case .requestFocus(let focus):
            var model = state
            model.focusRequestScheduled = false
            model.focusRequest = focus
            return Update(state: model)
        case .focusRequestScheduled:
            var model = state
            model.focusRequestScheduled = true
            return Update(state: model)
        case .focusChange(let focus):
            var model = state
            // UI-driven focus changes always wins.
            // - Toggle off any focus change request
            // - Set desired focus to this focus
            model.focusRequestScheduled = false
            model.focusRequest = focus
            model.focus = focus
            return Update(state: model)
        }
    }
}
