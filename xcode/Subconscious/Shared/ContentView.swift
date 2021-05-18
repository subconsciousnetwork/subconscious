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
typealias AppStore = Store<AppModel, AppAction, AppEnvironment>


//  MARK: App Actions
/// Actions that may be taken on the Store
enum AppAction {
    case editor(_ action: EditorAction)
    case searchBar(_ action: SubSearchBarAction)
    case search(_ action: SearchAction)
    case suggestionTokens(_ action: TextTokenBarAction)
    case appear
    case edit(_ document: SubconsciousDocument)
    case commitQuery(_ query: String)
    case setLiveQuery(_ query: String)
    case setEditorPresented(_ isPresented: Bool)
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

func tagSearchBarAction(_ action: SubSearchBarAction) -> AppAction {
    switch action {
    case .commitQuery(let query):
        return .commitQuery(query)
    case .setLiveQuery(let query):
        return .setLiveQuery(query)
    default:
        return .searchBar(action)
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

func tagSuggestionListAction(_ action: SuggestionListAction) -> AppAction {
    switch action {
    case .select(let suggestion):
        return .commitQuery(suggestion.description)
    }
}

func tagSuggestionTokensAction(_ action: TextTokenBarAction) -> AppAction {
    switch action {
    case .select(let text):
        return .commitQuery(text)
    default:
        return .suggestionTokens(action)
    }
}

//  MARK: App State
/// Central source of truth for all shared app state
struct AppModel: Equatable {
    var searchBar = SubSearchBarModel()
    var search = SearchModel(documents: [])
    /// Semi-permanent suggestions that show up as tokens in the search view.
    /// We don't differentiate between types of token, so these are all just strings.
    var suggestionTokens = TextTokenBarModel()
    /// Live-as-you-type suggestions
    var suggestions: [Suggestion] = []
    var editor = EditorModel()
    var isEditorPresented = false
}

//  MARK: App Reducer
/// Reducer for state
/// Mutates state in response to actions, returning effects
func updateApp(
    state: inout AppModel,
    action: AppAction,
    environment: AppEnvironment
) -> AnyPublisher<AppAction, Never> {
    switch action {
    case .editor(let action):
        return updateEditor(
            state: &state.editor,
            action: action,
            environment: environment
        ).map(tagEditorAction).eraseToAnyPublisher()
    case .searchBar(let action):
        return updateSubSearchBar(
            state: &state.searchBar,
            action: action
        ).map(tagSearchBarAction).eraseToAnyPublisher()
    case .search(let action):
        return updateSearch(
            state: &state.search,
            action: action,
            environment: environment
        ).map(tagSearchAction).eraseToAnyPublisher()
    case .suggestionTokens(let action):
        return updateTextTokenBar(
            state: &state.suggestionTokens,
            action: action,
            environment: BasicEnvironment(logger: environment.logger)
        ).map(tagSuggestionTokensAction).eraseToAnyPublisher()
    case .appear:
        let dir = environment.documentService.documentDirectory?
            .absoluteString ?? ""
        environment.logger.info(
            """
            AppAction.appear
            User Directory: \(dir)
            """
        )
        let initialQueryEffect = Just(AppAction.commitQuery(""))
        let suggestionTokensEffect = environment
            .fetchSuggestionTokens()
            .map({ suggestions in
                AppAction.suggestionTokens(.setTokens(suggestions))
            })
        return Publishers.Merge(
            initialQueryEffect,
            suggestionTokensEffect
        ).eraseToAnyPublisher()
    case .edit(let document):
        state.isEditorPresented = true
        return Just(.editor(.edit(document))).eraseToAnyPublisher()
    case .setEditorPresented(let isPresented):
        state.isEditorPresented = isPresented
    case .commitQuery(let query):
        let searchBarEffect = updateSubSearchBar(
            state: &state.searchBar,
            action: .commitQuery(query)
        ).map(tagSearchBarAction)

        let suggestionsEffect = environment
            .fetchSuggestions(query: query)
            .map(AppAction.setSuggestions)

        let documentQueryEffect = environment
            .documentService.query(query: query)
            .map({ documents in AppAction.search(.setItems(documents)) })
        
        return Publishers.Merge3(
            searchBarEffect,
            suggestionsEffect,
            documentQueryEffect
        ).eraseToAnyPublisher()
    case .setLiveQuery(let query):
        let searchBarEffect = updateSubSearchBar(
            state: &state.searchBar,
            action: .setLiveQuery(query)
        ).map(tagSearchBarAction)

        let suggestionsEffect = environment
            .fetchSuggestions(query: query)
            .map(AppAction.setSuggestions)

        return Publishers.Merge(
            searchBarEffect,
            suggestionsEffect
        ).eraseToAnyPublisher()
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
struct ContentView: View, Equatable {
    static func == (lhs: ContentView, rhs: ContentView) -> Bool {
        lhs.store.state == rhs.store.state
    }
    
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if (
                    !store.state.searchBar.isOpen &&
                    !store.state.searchBar.comittedQuery.isEmpty
                ) {
                    Button(
                        action: {
                            store.send(.commitQuery(""))
                        },
                        label: {
                            Icon(image: Image(systemName: "chevron.left"))
                        }
                    )
                }
                SubSearchBarView(
                    store: ViewStore(
                        state: store.state.searchBar,
                        send: store.send,
                        tag: tagSearchBarAction
                    )
                ).equatable()
            }.padding(8)

            ZStack {
                if store.state.searchBar.comittedQuery.isEmpty {
                    StreamView().equatable()
                } else {
                    SearchView(
                        store: ViewStore(
                            state: store.state.search,
                            send: store.send,
                            tag: tagSearchAction
                        )
                    ).equatable()
                }

                PinBottomRight {
                    Button(action: {
                        store.send(.setEditorPresented(true))
                    }) {
                        ActionButton()
                    }
                }

                Group {
                    if store.state.searchBar.isOpen {
                        ScrollView {
                            VStack(spacing: 0) {
                                if (store.state.searchBar.liveQuery.isEmpty) {
                                    TextTokenBarView(
                                        store: ViewStore(
                                            state: store.state.suggestionTokens,
                                            send: store.send,
                                            tag: tagSuggestionTokensAction
                                        )
                                    )
                                    .equatable()
                                    .padding(.top, 0)
                                    .padding(.bottom, 8)
                                }
                                Divider()
                                SuggestionListView(
                                    store: ViewStore(
                                        state: store.state.suggestions,
                                        send: store.send,
                                        tag: tagSuggestionListAction
                                    )
                                ).equatable()
                            }
                        }
                        .background(Color.Subconscious.background)
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
                store: ViewStore(
                    state: store.state.editor,
                    send: store.send,
                    tag: tagEditorAction
                )
            ).equatable()
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
