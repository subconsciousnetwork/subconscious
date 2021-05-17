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
    case titleField(_ action: TextFieldWithToggleAction)
    case appear
    case edit(SubconsciousDocument)
    case save(SubconsciousDocument)
    case cancel
    case clear
    case selectTitle(_ text: String)
    case requestSave(SubconsciousDocument)
    case queryTitleSuggestions(_ query: String)
    case requestTitleMatch(_ title: String)
    case requestEditorUnpresent
    case setTitle(_ title: String)
    case setTitleSuggestions(_ suggestions: [Suggestion])
}


//  MARK: State
struct EditorModel: Equatable {
    var titleField = TextFieldWithToggleModel(
        text: "",
        placeholder: ""
    )
    var body = TextareaModel()
    var titleSuggestions: [Suggestion] = []
}

func tagEditorBody(_ action: TextareaAction) -> EditorAction {
    switch action {
    default:
        return EditorAction.body(action)
    }
}

func tagEditorTitleField(_ action: TextFieldWithToggleAction) -> EditorAction {
    switch action {
    case .setText(let text):
        return .setTitle(text)
    default:
        return EditorAction.titleField(action)
    }
}

func tagTitleSuggestionList(_ action: SuggestionListAction) -> EditorAction {
    switch action {
    case .select(let suggestion):
        return .selectTitle(suggestion.description)
    }
}


//  MARK: Reducer
func updateEditor(
    state: inout EditorModel,
    action: EditorAction,
    environment: AppEnvironment
) -> AnyPublisher<EditorAction, Never> {
    switch action {
    case .body(let action):
        return updateTextarea(
            state: &state.body,
            action: action
        ).map(tagEditorBody).eraseToAnyPublisher()
    case .titleField(let action):
        return updateTextFieldWithToggle(
            state: &state.titleField,
            action: action
        ).map(tagEditorTitleField).eraseToAnyPublisher()
    case .appear:
        let querySuggestions = EditorAction.queryTitleSuggestions("")
        return Just(querySuggestions)
            .eraseToAnyPublisher()
    case .setTitle(let title):
        let setTitle = EditorAction.titleField(.setText(title))
        let querySuggestions = EditorAction.queryTitleSuggestions(title)
        return Publishers.Merge(
            Just(setTitle),
            Just(querySuggestions)
        ).eraseToAnyPublisher()
    case .setTitleSuggestions(let suggestions):
        state.titleSuggestions = suggestions
    case .edit(let document):
        let setTitle = Just(
            EditorAction.setTitle(document.title)
        )
        let setBody = Just(
            EditorAction.body(.set(document.content.description))
        )
        return Publishers.Merge(setTitle, setBody)
            .eraseToAnyPublisher()
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
        let setTitle = Just(
            EditorAction.setTitle("")
        )
        let setBody = Just(
            EditorAction.body(.set(""))
        )
        return Publishers.Merge(setTitle, setBody)
            .eraseToAnyPublisher()
    case .selectTitle(let text):
        let setTitle = EditorAction.setTitle(text)
        let requestMatch = EditorAction.requestTitleMatch(text)
        let closeSuggestions = EditorAction.titleField(
            .setToggle(isActive: false)
        )
        return Publishers.Merge3(
            Just(setTitle),
            Just(requestMatch),
            Just(closeSuggestions)
        ).eraseToAnyPublisher()
    case .queryTitleSuggestions(let query):
        return environment.fetchSuggestions(query: query)
            .map({ suggestions in .setTitleSuggestions(suggestions) })
            .eraseToAnyPublisher()
    case .requestSave:
        environment.logger.warning(
            """
            EditorAction.requestSave
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
    
    init(store: ViewStore<EditorModel, EditorAction>) {
        print("EditorView.init")
        self.store = store
    }
    
    var body: some View {
        print("EditorView.body")
        
        return VStack(spacing: 0) {
            HStack {
                Button(cancel) {
                    store.send(.cancel)
                }
                Spacer()
                Button(action: {
                    store.send(.save(
                        SubconsciousDocument(
                            title: store.state.titleField.text,
                            markup: store.state.body.text
                        )
                    ))
                }) {
                    Text(save)
                }
            }.padding(16)
            HStack(spacing: 8) {
                Text(titlePlaceholder)
                    .foregroundColor(Color.Subconscious.secondaryText)
                TextFieldWithToggleView(
                    store: ViewStore(
                        state: store.state.titleField,
                        send: store.send,
                        tag: tagEditorTitleField
                    )
                ).equatable()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Divider()
            Group {
                if store.state.titleField.isToggleActive {
                    ScrollView {
                        SuggestionListView(
                            store: ViewStore(
                                state: store.state.titleSuggestions,
                                send: store.send,
                                tag: tagTitleSuggestionList
                            )
                        ).equatable()
                    }
                } else {
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
        }.onAppear {
            store.send(.appear)
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
