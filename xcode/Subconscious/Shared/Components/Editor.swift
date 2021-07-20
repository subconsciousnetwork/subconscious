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
import Elmo

//  MARK: Actions
enum EditorAction {
    /// Set URL property
    case setURL(_ url: URL?)
    /// Set TextViewRepresentable
    case setBody(_ text: String)
    /// Edit content
    case edit(url: URL?, content: String)
    case save(url: URL?, content: String)
    case cancel
    case requestSave(url: URL?, content: String)
    case requestEditorUnpresent
    
    static let clear = setBody("")
}


//  MARK: State
struct EditorModel: Equatable {
    var url: URL?
    var body = ""
}


//  MARK: Reducer
func updateEditor(
    state: inout EditorModel,
    action: EditorAction,
    environment: Logger
) -> AnyPublisher<EditorAction, Never> {
    switch action {
    case .edit(let url, let content):
        return Publishers.Merge(
            Just(EditorAction.setURL(url)),
            Just(EditorAction.setBody(content))
        ).eraseToAnyPublisher()
    case .setURL(let url):
        state.url = url
    case .setBody(let text):
        state.body = text
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
                            content: store.state.body
                        )
                    )
                }) {
                    Text(save).bold()
                }
            }
            .padding(16)
            Divider()
            TextViewRepresentable(
                text: Binding(
                    get: { store.state.body },
                    set: { text in store.send(.setBody(text)) }
                )
            )
            .insets(
                EdgeInsets(
                    top: 24,
                    leading: 16,
                    bottom: 24,
                    trailing: 16
                )
            )
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
