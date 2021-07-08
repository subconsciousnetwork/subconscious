//
//  Editor.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/27/21.
//

import Foundation
import Combine
import SwiftUI
import os

//  MARK: Actions
enum EditorAction {
    case body(_ action: TextareaAction)
    case setPath(_ url: URL?)
    case edit(url: URL?, content: String)
    case save(url: URL?, content: String)
    case cancel
    case requestSave(url: URL?, content: String)
    case requestEditorUnpresent

    static let clear = setBody("")
    
    static func setBody(_ text: String) -> Self {
        .body(.set(text))
    }
}


//  MARK: State
struct EditorModel: Equatable {
    var url: URL?
    var body = TextareaModel()
}

func tagEditorBody(_ action: TextareaAction) -> EditorAction {
    switch action {
    default:
        return EditorAction.body(action)
    }
}


//  MARK: Reducer
func updateEditor(
    state: inout EditorModel,
    action: EditorAction,
    environment: Logger
) -> AnyPublisher<EditorAction, Never> {
    switch action {
    case .body(let action):
        return updateTextarea(
            state: &state.body,
            action: action
        ).map(tagEditorBody).eraseToAnyPublisher()
    case .edit(let path, let content):
        return Publishers.Merge(
            Just(EditorAction.setPath(path)),
            Just(EditorAction.setBody(content))
        ).eraseToAnyPublisher()
    case .setPath(let url):
        state.url = url
    case .save(let url, let content):
        let save = Just(
            EditorAction.requestSave(url: url, content: content)
        )
        let unpresent = Just(EditorAction.requestEditorUnpresent)
        let clear = Just(EditorAction.clear).delay(
            for: .milliseconds(500),
            scheduler: RunLoop.main
        )
        return Publishers.Merge3(save, unpresent, clear).eraseToAnyPublisher()
    case .cancel:
        let unpresent = Just(EditorAction.requestEditorUnpresent)
        // Delay for a bit. Should clear just after sheet animation completes.
        // Note that SwiftUI animations don't yet have reasonable
        // onComplete handlers, so we're making do.
        let clear = Just(EditorAction.setBody("")).delay(
            for: .milliseconds(500),
            scheduler: RunLoop.main
        )
        return Publishers.Merge(unpresent, clear).eraseToAnyPublisher()
    case .requestSave:
        environment.warning(
            """
            EditorAction.requestSave
            should be handled by the parent view.
            """
        )
    case .requestEditorUnpresent:
        environment.warning(
            """
            EditorAction.requestEditorUnpresent
            should be handled by the parent view.
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: View
struct EditorView: View, Equatable {
    static func == (lhs: EditorView, rhs: EditorView) -> Bool {
        lhs.store == rhs.store
    }
    
    let store: ViewStore<EditorModel, EditorAction>
    let save: LocalizedStringKey = "Save"
    let cancel: LocalizedStringKey = "Cancel"
    let edit: LocalizedStringKey = "Edit"
    let titlePlaceholder: LocalizedStringKey = "Title:"
        
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(cancel) {
                    store.send(.cancel)
                }
                Spacer()
                Button(action: {
                    store.send(
                        .save(
                            url: store.state.url,
                            content: store.state.body.text
                        )
                    )
                }) {
                    Text(save)
                }
            }
            .padding(16)

            TextareaView(
                store: ViewStore(
                    state: store.state.body,
                    send: store.send,
                    tag: tagEditorBody
                )
            )
            .equatable()
            // Note that TextEditor has some internal padding
            // about 4px, eyeballing it with a straightedge.
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(
            store: ViewStore(state: EditorModel(), send: { action in })
        )
    }
}
