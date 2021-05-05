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
    case edit(SubconsciousDocument)
    case save(SubconsciousDocument)
    case cancel
    case clear
    case selectTitle(_ text: String)
    case requestSave(SubconsciousDocument)
    case requestSuggestions(SubconsciousDocument)
    case requestTitleMatch(_ title: String)
    case requestEditorUnpresent
    case setTitleSuggestionsOpen(isOpen: Bool)
    case setTitle(title: String)
    case setBody(body: String)
}

struct EditorState {
    var title: String = ""
    var body: String = ""
    var titleSuggestions: [Suggestion] = [
        .query(.init(text: "Evolution")),
        .query(.init(text: "Evolution selects for good enough")),
        .query(.init(text: "The Evolution of Civilizations￼"))
    ]
    var isTitleSuggestionsOpen = false
}

func editorReducer(
    state: inout EditorState,
    action: EditorAction,
    environment: AppEnvironment
) -> AnyPublisher<EditorAction, Never> {
    switch action {
    case .setTitleSuggestionsOpen(let isOpen):
        state.isTitleSuggestionsOpen = isOpen
    case .setTitle(let title):
        state.title = title
    case .setBody(let body):
        state.body = body
    case .edit(let document):
        state.title = document.title
        state.body = document.content.description
    case .save(let document):
        let save = Just(EditorAction.requestSave(document))
        let unpresent = Just(EditorAction.requestEditorUnpresent)
        let clear = Just(EditorAction.clear).delay(
            for: .milliseconds(500),
            scheduler: RunLoop.main
        )
        return Publishers.Merge3(save, unpresent, clear)
            .eraseToAnyPublisher()
    case .cancel:
        let unpresent = Just(EditorAction.requestEditorUnpresent)
        // Delay for a bit. Should clear just after sheet animation completes.
        // Note that SwiftUI animations don't yet have reasonable
        // onComplete handlers, so we're making do.
        let clear = Just(EditorAction.clear).delay(
            for: .milliseconds(500),
            scheduler: RunLoop.main
        )
        return Publishers.Merge(unpresent, clear).eraseToAnyPublisher()
    case .clear:
        state.title = ""
        state.body = ""
    case .selectTitle(let text):
        let title = Just(EditorAction.setTitle(title: text))
        let match = Just(EditorAction.requestTitleMatch(text))
        let close = Just(EditorAction.setTitleSuggestionsOpen(isOpen: false))
        return Publishers.Merge3(title, match, close)
            .eraseToAnyPublisher()
    case .requestSave:
        environment.logger.warning(
            """
            EditorAction.requestSave
            should be handled by the parent view.
            """
        )
    case .requestSuggestions:
        environment.logger.warning(
            """
            EditorAction.requestSuggestions
            should be handled by the parent view.
            """
        )
    case .requestTitleMatch:
        environment.logger.warning(
            """
            EditorAction.requestTitleMatch
            should be handled by parent view.
            """
        )
    case .requestEditorUnpresent:
        environment.logger.warning(
            """
            EditorAction.requestEditorUnpresent
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
    var titlePlaceholder: LocalizedStringKey = "Title:"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(cancel) {
                    send(.cancel)
                }
                Spacer()
                Button(action: {
                    send(.save(
                        SubconsciousDocument(
                            title: state.title,
                            markup: state.body
                        )
                    ))
                }) {
                    Text(save)
                }
            }.padding(16)
            HStack(spacing: 8) {
                Text(titlePlaceholder)
                    .foregroundColor(.secondary)
                TextField(
                    "",
                    text: Binding(
                        get: { state.title },
                        set: { value in
                            send(.setTitle(title: value))
                        }
                    ),
                    onEditingChanged: { editingChanged in
                        send(.setTitleSuggestionsOpen(isOpen: editingChanged))
                    },
                    onCommit: {
                        send(.selectTitle(state.title))
                    }
                )
                .onTapGesture(perform: {
                    send(.setTitleSuggestionsOpen(isOpen: true))
                })
                Group {
                    if !state.title.isEmpty {
                        Button(
                            action: {
                                send(.setTitle(title: ""))
                            },
                            label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.primary)
                            }
                        )
                    } else if state.isTitleSuggestionsOpen {
                        Button(
                            action: {
                                send(.setTitleSuggestionsOpen(isOpen: false))
                            },
                            label: {
                                Image(systemName: "chevron.up.circle")
                                    .foregroundColor(.primary)
                            }
                        )
                    } else {
                        Button(
                            action: {
                                send(.setTitleSuggestionsOpen(isOpen: true))
                            },
                            label: {
                                Image(systemName: "chevron.down.circle")
                                    .foregroundColor(.primary)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Divider()
            Group {
                if state.isTitleSuggestionsOpen {
                    List(state.titleSuggestions) { suggestion in
                        Button(
                            action: {
                                send(.selectTitle(suggestion.text))
                            },
                            label: {
                                SuggestionRowView(suggestion: suggestion)
                            }
                        )
                    }
                } else {
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
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(
            state: EditorState(),
            send: { action in }
        )
    }
}
