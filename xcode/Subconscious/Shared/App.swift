//
//  App.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/21/21.
//

import Foundation
import Combine
import os


typealias AppStore = Store<AppState, AppAction, AppEnvironment>

//  MARK: App Actions
/// Actions that may be taken on the Store
enum AppAction {
    case editor(_ action: EditorAction)
    case search(_ action: SearchAction)
    case appear
    case edit(_ document: SubconsciousDocument)
    case query(_ query: String)
    case searchResults(query: String)
    case setEditorPresented(_ isPresented: Bool)
    case setResults(results: [Result])
    case saveThread(SubconsciousDocument)
    case warning(_ message: String)
    case info(_ message: String)
}

//  MARK: App Environment
/// Access to external network services and other supporting services
struct AppEnvironment {
    let logger = Logger(
        subsystem: "com.subconscious.Subconscious",
        category: "main"
    )

    let documentService = DocumentService()
        
    func fetchResults(query: String) -> AnyPublisher<[Result], Never> {
        return Just(
            [
                Result.thread(
                    ThreadResult(text: "If you have 70 notecards, you have a movie")
                ),
                Result.thread(
                    ThreadResult(text: "Tenuki")
                ),
                Result.query(
                    QueryResult(text: "Notecard")
                ),
                Result.create(
                    CreateResult(text: "Notecard")
                ),
            ]
        ).eraseToAnyPublisher()
    }
}

//  MARK: App State
/// Central source of truth for all shared app state
struct AppState {
    var resultQuery: String = ""
    var threadQuery: String = ""
    var results: [Result] = []
    var search: SearchModel = SearchModel(documents: [])
    var isEditorPresented = false
    var editor: EditorState = EditorState.init()
}

//  MARK: Reducer
/// Reducer for state
/// Mutates state in response to actions, returning effects
func appReducer(
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
        return Just(.searchResults(query: state.resultQuery))
            .eraseToAnyPublisher()
    case .edit(let document):
        state.isEditorPresented = true
        return Just(.editor(.edit(document))).eraseToAnyPublisher()
    case .editor(let action):
        return editorReducer(
            state: &state.editor,
            action: action,
            environment: environment
        ).map(AppAction.editor).eraseToAnyPublisher()
    case .search(let action):
        return updateSearch(
            state: &state.search,
            action: action,
            environment: environment
        ).map(tagSearchView).eraseToAnyPublisher()
    case .setEditorPresented(let isPresented):
        state.isEditorPresented = isPresented
    case let .searchResults(query):
        state.resultQuery = query
        return environment
            .fetchResults(query: query)
            .map(AppAction.setResults(results:))
            .eraseToAnyPublisher()
    case let .query(query):
        state.resultQuery = query
        state.threadQuery = query
        return Publishers.Merge(
            environment.fetchResults(query: query)
                .map(AppAction.setResults(results:)),
            environment.documentService.query(query: query)
                .map({ documents in .search(.setItems(documents)) })
        ).eraseToAnyPublisher()
    case let .setResults(results):
        state.results = results
    case let .saveThread(thread):
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
