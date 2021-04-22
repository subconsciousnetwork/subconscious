//
//  App.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/21/21.
//

import Foundation
import Combine


typealias AppEffect = Effect<AppAction>
typealias AppStore = Store<AppState, AppAction, AppEnvironment>

//  MARK: App Actions
/// Actions that may be taken on the Store
enum AppAction {
    case appear
    case search(query: String)
    case searchResults(query: String)
    case setResults(results: [Result])
    case setThreads(threads: [Thread])
}

//  MARK: App Environment
/// Access to external network services and other supporting services
struct AppEnvironment {
    func fetchResultsAndThreads(query: String) -> AppEffect {
        Publishers.Merge(
            fetchResults(query: query),
            fetchThreads(query: query)
        ).eraseToAnyPublisher()
    }

    func fetchResults(query: String) -> AppEffect {
        return Just(
            AppAction.setResults(
                results: [
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
            )
        ).eraseToAnyPublisher()
    }
    
    func fetchThreads(query: String) -> AppEffect {
        return Just(
            AppAction.setThreads(
                threads: [
                    Thread(
                        id: UUID(),
                        title: "Hello",
                        blocks: [
                            Block.text(TextBlock(text: "I am a text block")),
                            Block.text(TextBlock(text: "I am also a text block")),
                            Block.heading(HeadingBlock(text: "Heading block")),
                            Block.text(TextBlock(text: "Some more text")),
                        ]
                    ),
                    Thread(
                        id: UUID(),
                        title: "World",
                        blocks: [
                            Block.text(TextBlock(text: "I am a text block")),
                            Block.text(TextBlock(text: "I am also a text block")),
                            Block.heading(HeadingBlock(text: "Heading block")),
                            Block.text(TextBlock(text: "Some more text")),
                        ]
                    ),
                ]
            )
        ).eraseToAnyPublisher()
    }
}

//  MARK: App State
/// Central source of truth for all shared app state
struct AppState {
    var resultQuery: String = ""
    var threadQuery: String = ""
    var results: [Result] = []
    var threads: [Thread] = []
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
        return Just(.searchResults(query: state.resultQuery))
            .eraseToAnyPublisher()
    case let .searchResults(query):
        state.resultQuery = query
        return environment.fetchResults(query: query)
    case let .search(query):
        state.resultQuery = query
        state.threadQuery = query
        return environment.fetchResultsAndThreads(query: query)
    case let .setResults(results):
        state.results = results
    case let .setThreads(threads):
        state.threads = threads
    }
    return Empty().eraseToAnyPublisher()
}
