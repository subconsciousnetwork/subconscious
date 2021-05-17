//
//  Textarea.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/10/21.
//

import SwiftUI
import Combine

enum TextareaAction {
    case set(_ text: String)
    case change(_ text: String)
}

struct TextareaModel: Equatable {
    var text = ""
}

func updateTextarea(
    state: inout TextareaModel,
    action: TextareaAction
) -> AnyPublisher<TextareaAction, Never> {
    switch action {
    case .change(let text):
        state.text = text
    case .set(let text):
        print("updateTextarea", text)
        state.text = text
    }
    return Empty().eraseToAnyPublisher()
}

/// TextareaView provides an Elm App Architecture-style view for a TextEditor-like view.
struct TextareaView: View, Equatable {
    static func == (lhs: TextareaView, rhs: TextareaView) -> Bool {
        lhs.store == rhs.store
    }

    /// Used as a scratchpad for the TextEditor.
    /// If we hand TextEditor a binding that references model state directly, we get issues with
    /// cursor position loss. Decoupling the state that is written to by the editor, from the state that is
    /// referenced by the application resolves the issue.
    @State private var textState = ""
    let store: ViewStore<TextareaModel, TextareaAction>
    
    var body: some View {
        print("TextareaView.body")
        return TextEditor(
            text: $textState
        )
        .onChange(
            of: textState,
            perform: { text in store.send(.change(text)) }
        )
        // TODO: Figure out what's going on here with the update cycle.
        // It's a bit beyond me why this works, but it does 2021-05-17
        .onChange(of: store.state.text, perform: { text in
            self.textState = text
        })
    }
}

struct TextareaView_Previews: PreviewProvider {
    static var previews: some View {
        TextareaView(
            store: ViewStore(
                state: TextareaModel(),
                send: { action in }
            )
        )
    }
}
