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

enum EditorAction {
    case setTitle(title: String)
    case setBody(body: String)
    case edit(SubconsciousDocument)
    case requestSave(SubconsciousDocument)
    case requestEditorUnpresent
}

struct EditorState {
    var title: String = ""
    var body: String = ""
}

func editorReducer(
    state: inout EditorState,
    action: EditorAction,
    environment: AppEnvironment
) -> AnyPublisher<EditorAction, Never> {
    switch action {
    case .setTitle(let title):
        state.title = title
    case .setBody(let body):
        state.body = body
    case .edit(let document):
        state.title = document.title
        state.body = document.content.description
    case .requestSave:
        environment.logger.warning(
            """
            EditorAction.requestSave
            should be handled by the parent view.
            """
        )
    case .requestEditorUnpresent:
        environment.logger.warning(
            """
            EditorAction.requestCloseEditor
            should be handled by the parent view.
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

struct EditorView: View {
    var state: EditorState
    var send: (EditorAction) -> Void
    var save: LocalizedStringKey = "Save"
    var cancel: LocalizedStringKey = "Cancel"
    var edit: LocalizedStringKey = "Edit"
    var titlePlaceholder: LocalizedStringKey = "Title"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(cancel) {
                    send(.requestEditorUnpresent)
                }
                Spacer()
                Button(action: {
                    send(.requestSave(
                        SubconsciousDocument(
                            title: state.title,
                            markup: state.body
                        )
                    ))
                }) {
                    Text(save)
                }
            }.padding(16)
            TextField(
                titlePlaceholder,
                text: Binding(
                    get: { state.title },
                    set: { value in
                        send(EditorAction.setTitle(title: value))
                    }
                )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Divider()
            TextEditor(
                text: Binding(
                    get: { state.body },
                    set: { value in
                        send(EditorAction.setBody(body: value))
                    }
                )
            )
            // Note that TextEditor has some internal padding
            // about 4px, eyeballing it with a straightedge.
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
    }
}

//struct EditorView_Previews: PreviewProvider {
//    static var previews: some View {
//
//    }
//}
