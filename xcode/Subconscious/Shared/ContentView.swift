//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//

import SwiftUI
import Foundation
import Combine
import os


//  MARK: AppStore typealias
typealias AppStore = Store<AppState, AppAction, AppEnvironment>


//  MARK: App Actions
/// Actions that may be taken on the Store
enum AppAction {
    case editor(_ action: EditorAction)
    case search(_ action: SearchAction)
    case appear
    case edit(_ document: SubconsciousDocument)
    case query(_ query: String)
    case querySuggestions(query: String)
    case setEditorPresented(_ isPresented: Bool)
    case setSuggestionsOpen(_ isOpen: Bool)
    case setSuggestions(_ suggestions: [Suggestion])
    case saveThread(SubconsciousDocument)
    case warning(_ message: String)
    case info(_ message: String)
}

//  MARK: Tagging functions

func tagEditorAction(_ action: EditorAction) -> AppAction {
    switch action {
    case .requestEditorUnpresent:
        return .setEditorPresented(false)
    case .requestSave(let thread):
        return .saveThread(thread)
    default:
        return .editor(action)
    }
}

func tagSearchAction(_ action: SearchAction) -> AppAction {
    switch action {
    case .requestEdit(let document):
        return .edit(document)
    default:
        return .search(action)
    }
}

//  MARK: App Environment
/// Access to external network services and other supporting services
struct AppEnvironment {
    let logger = Logger(
        subsystem: "com.subconscious.Subconscious",
        category: "main"
    )

    let documentService = DocumentService()
    
    ///  FIXME: this just serves up static suggestions
    func fetchSuggestions(query: String) -> Future<[Suggestion], Never> {
        Future({ promise in
            var suggestions = [
                Suggestion.thread(
                    .init(text: "If you have 70 notecards, you have a movie")
                ),
                Suggestion.thread(.init(text: "Tenuki")),
                Suggestion.query(.init(text: "Notecard")),
            ]
            if !query.isEmpty {
                suggestions.append(.create(.init(text: query)))
            }
            promise(.success(suggestions))
        })
    }
}

//  MARK: App State
/// Central source of truth for all shared app state
struct AppState {
    var suggestionQuery: String = ""
    var threadQuery: String = ""
    var suggestions: [Suggestion] = []
    var search: SearchModel = SearchModel(documents: [])
    var isSuggestionsOpen = false
    var isEditorPresented = false
    var editor: EditorState = EditorState.init()
}

//  MARK: App Reducer
/// Reducer for state
/// Mutates state in response to actions, returning effects
func updateApp(
    state: inout AppState,
    action: AppAction,
    environment: AppEnvironment
) -> AnyPublisher<AppAction, Never> {
    switch action {
    case .appear:
        let dir = environment.documentService.documentDirectory?
            .absoluteString ?? ""
        environment.logger.info(
            """
            AppAction.appear
            User Directory: \(dir)
            """
        )
        return Just(.querySuggestions(query: state.suggestionQuery))
            .eraseToAnyPublisher()
    case .edit(let document):
        state.isEditorPresented = true
        return Just(.editor(.edit(document))).eraseToAnyPublisher()
    case .editor(let action):
        return editorReducer(
            state: &state.editor,
            action: action,
            environment: environment
        ).map(tagEditorAction).eraseToAnyPublisher()
    case .search(let action):
        return updateSearch(
            state: &state.search,
            action: action,
            environment: environment
        ).map(tagSearchAction).eraseToAnyPublisher()
    case .setEditorPresented(let isPresented):
        state.isEditorPresented = isPresented
    case .query(let query):
        state.suggestionQuery = query
        state.threadQuery = query
        state.isSuggestionsOpen = false
        return Publishers.Merge(
            environment.fetchSuggestions(query: query)
                .map(AppAction.setSuggestions),
            environment.documentService.query(query: query)
                .map({ documents in .search(.setItems(documents)) })
        ).eraseToAnyPublisher()
    case .querySuggestions(let query):
        state.suggestionQuery = query
        return environment
            .fetchSuggestions(query: query)
            .map(AppAction.setSuggestions)
            .eraseToAnyPublisher()
    case .setSuggestionsOpen(let isOpen):
        state.isSuggestionsOpen = isOpen
    case .setSuggestions(let suggestions):
        state.suggestions = suggestions
    case .saveThread(let thread):
        return environment.documentService.write(thread)
            .map({ AppAction.info("Saved thread") })
            .eraseToAnyPublisher()
    case .warning(let message):
        environment.logger.warning("\(message)")
    case .info(let message):
        environment.logger.info("\(message)")
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: ContentView
struct ContentView: View {
    @StateObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if (
                    !store.state.isSuggestionsOpen &&
                    !store.state.threadQuery.isEmpty
                ) {
                    Button(action: {
                        store.send(.query(""))
                    }) {
                        Icon(image: Image(systemName: "chevron.left"))
                    }
                }
                SearchBarView(
                    comittedQuery: Binding(
                        get: { store.state.threadQuery },
                        set: { query in
                            store.send(.query(query))
                        }
                    ),
                    liveQuery: Binding(
                        get: { store.state.suggestionQuery },
                        set: { query in
                            store.send(.querySuggestions(query: query))
                        }
                    ),
                    isOpen: Binding(
                        get: { store.state.isSuggestionsOpen },
                        set: { isOpen in
                            store.send(.setSuggestionsOpen(isOpen))
                        }
                    )
                )
            }.padding(8)
            Divider()
            ZStack {
                if store.state.threadQuery.isEmpty {
                    StreamView()
                } else {
                    SearchView(
                        state: store.state.search,
                        send: address(
                            send: store.send,
                            tag: tagSearchAction
                        )
                    )
                }

                PinBottomRight {
                    Button(action: {
                        store.send(.setEditorPresented(true))
                    }) {
                        ActionButton()
                    }
                }

                VStack {
                    if store.state.isSuggestionsOpen {
                        SuggestionsView(
                            suggestions: store.state.suggestions,
                            send: store.send
                        )
                    }
                }
            }
        }
        .onAppear {
            store.send(.appear)
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.isEditorPresented },
                set: { isPresented in
                    store.send(.setEditorPresented(isPresented))
                }
            )
        ) {
            EditorView(
                state: store.state.editor,
                send: address(send: store.send, tag: tagEditorAction)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: AppStore(
            state: .init(),
            reducer: updateApp,
            environment: .init()
        ))
    }
}
