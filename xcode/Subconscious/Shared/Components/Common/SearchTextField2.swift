//
//  SearchTextField2.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI
import ObservableStore

//  MARK: Action
enum SearchTextFieldAction: Hashable {
    case focus(AppFocusAction)
    case setText(String)

    static func requestFocusImmediate(_ focus: AppFocus?) -> Self {
        .focus(.requestFocusImmediate(focus))
    }

    static func focusChange(_ focus: AppFocus?) -> Self {
        .focus(.focusChange(focus))
    }
}

//  MARK: Cursors
struct SearchTextFieldFocusCursor: CursorProtocol {
    static func get(state: SearchTextFieldModel) -> AppFocusModel {
        state.focus
    }

    static func set(
        state: SearchTextFieldModel,
        inner: AppFocusModel
    ) -> SearchTextFieldModel {
        var model = state
        model.focus = inner
        return state
    }

    static func tag(action: AppFocusAction) -> SearchTextFieldAction {
        .focus(action)
    }
}


//  MARK: Model
struct SearchTextFieldModel: Hashable {
    var placeholder = ""
    var text = ""
    var focus = AppFocusModel()
    var field: AppFocus

    //  MARK: Update
    static func update(
        state: SearchTextFieldModel,
        action: SearchTextFieldAction,
        environment: Void
    ) -> Update<SearchTextFieldModel, SearchTextFieldAction> {
        switch action {
        case .focus(let action):
            return SearchTextFieldFocusCursor.update(
                with: FocusModel.update,
                state: state,
                action: action,
                environment: ()
            )
        case .setText(let text):
            var model = state
            model.text = text
            return Update(state: model)
        }
    }
}

struct SearchTextField2: View {
    @FocusState private var focusState: AppFocus?
    var store: ViewStore<SearchTextFieldModel, SearchTextFieldAction>

    var body: some View {
        TextField(
            store.state.placeholder,
            text: store.binding(
                get: \.text,
                tag: SearchTextFieldAction.setText
            )
        )
        .focused($focusState, equals: store.state.field)
        /// TODO I think we want to place these once at the root
        .onChange(of: self.focusState) { value in
            // Focus has changed Send notification
            store.send(.focusChange(value))
        }
        .onChange(of: self.store.state.focus.focusRequest) { value in
            self.focusState = value
        }
        .modifier(RoundedTextFieldViewModifier())
    }
}
