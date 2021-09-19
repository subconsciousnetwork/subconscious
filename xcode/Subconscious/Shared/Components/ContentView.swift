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
import Elmo

//  MARK: Store typealias
typealias ContentStore = Elmo.Store<ContentModel, ContentAction, ContentEnvironment>

//  MARK: Actions
/// Actions that may be taken on the Store
enum ContentAction {
    /// Database actions
    case database(DatabaseAction)
    /// Search Bar actions
    case searchBar(SubSearchBarAction)
    /// Search suggestions actions
    case suggestions(SuggestionsAction)
    /// Entry detail view
    case detail(ResultView.Action)
    /// On view appear
    case appear
    /// Issue and log search
    case commitQuery(String)
    /// Set live query
    case setQuery(String)
    case setSuggestions(_ suggestions: SuggestionsModel)
    case setDetailActive(Bool)
    case warning(String)
    case info(String)
}

//  MARK: Tagging functions

func tagDatabaseAction(_ action: DatabaseAction) -> ContentAction {
    .database(action)
}

func tagSearchBarAction(_ action: SubSearchBarAction) -> ContentAction {
    switch action {
    case .commit(let text):
        return .commitQuery(text)
    case .setText(let text):
        return .setQuery(text)
    default:
        return .searchBar(action)
    }
}

func tagSuggestionsAction(_ action: SuggestionsAction) -> ContentAction {
    switch action {
    case .select(let query):
        return .commitQuery(query)
    default:
        return .suggestions(action)
    }
}

func tagResultView(_ action: ResultView.Action) -> ContentAction {
    switch action {
    case .commitQuery(let query):
        return .commitQuery(query)
    default:
        return .detail(action)
    }
}

//  MARK: State
/// Central source of truth for all shared app state
struct ContentModel: Equatable {
    var isDetailActive = false
    var database = DatabaseModel()
    var searchBar = SubSearchBarModel()
    var detail = ResultView.Model()
    /// Live-as-you-type suggestions
    var suggestions = SuggestionsModel()
}

//  MARK: Reducer
/// Reducer for state
/// Mutates state in response to actions, returning effects
func updateContent(
    state: inout ContentModel,
    action: ContentAction,
    environment: ContentEnvironment
) -> AnyPublisher<ContentAction, Never> {
    switch action {
    case .database(let action):
        return updateDatabase(
            state: &state.database,
            action: action,
            environment: environment.database
        ).map(tagDatabaseAction).eraseToAnyPublisher()
    case .searchBar(let action):
        return updateSubSearchBar(
            state: &state.searchBar,
            action: action,
            environment: environment.io
        ).map(tagSearchBarAction).eraseToAnyPublisher()
    case .suggestions(let action):
        return updateSuggestions(
            state: &state.suggestions,
            action: action,
            environment: environment.io
        ).map(tagSuggestionsAction).eraseToAnyPublisher()
    case .detail(let action):
        return ResultView.update(
            state: &state.detail,
            action: action,
            environment: environment.io
        ).map(tagResultView).eraseToAnyPublisher()
    case .setDetailActive(let isDetailActive):
        state.isDetailActive = isDetailActive
    case .appear:
        environment.logger.info(
            """
            User Directory: \t\(environment.documentsUrl.absoluteString)
            """
        )
        let initialQueryEffect = Just(ContentAction.commitQuery(""))
        let setupDatabaseEffect = Just(ContentAction.database(.setup))
        return Publishers.Merge(
            initialQueryEffect,
            setupDatabaseEffect
        ).eraseToAnyPublisher()
    case .commitQuery(let query):
        let commit = Just(ContentAction.searchBar(.commit(query)))
        let suggest = Just(ContentAction.suggestions(.suggest(query)))
        let search = Just(ContentAction.detail(.search(query)))
        let setDetailActive = Just(
            ContentAction.setDetailActive(!query.isWhitespace)
        )
        return Publishers.Merge4(
            commit,
            suggest,
            search,
            setDetailActive
        ).eraseToAnyPublisher()
    case .setQuery(let query):
        let setText = Just(ContentAction.searchBar(.setText(query)))
        let suggest = Just(ContentAction.suggestions(.suggest(query)))
        return Publishers.Merge(
            setText,
            suggest
        ).eraseToAnyPublisher()
    case .setSuggestions(let suggestions):
        state.suggestions = suggestions
    case .warning(let message):
        environment.logger.warning("\(message)")
    case .info(let message):
        environment.logger.info("\(message)")
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: Environment
/// Access to external network services and other supporting services
struct ContentEnvironment {
    let documentsUrl = Constants.documentDirectoryURL
    let databaseUrl = Constants.databaseURL
    let logger = Constants.logger
    let database: DatabaseService
    let io: IOService

    init() {
        self.database = DatabaseService(
            databaseUrl: databaseUrl,
            documentsUrl: documentsUrl,
            migrations: Constants.migrations
        )

        self.io = IOService(
            logger: logger,
            database: database
        )
    }
}

//  MARK: View
struct ContentView: View {
    @StateObject private var store = ContentStore(
        state: .init(),
        reducer: updateContent,
        environment: .init()
    )

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                NavigationLink(
                    isActive: Binding(
                        get: { store.state.isDetailActive },
                        set: { isDetailActive in
                            store.send(.setDetailActive(isDetailActive))
                        }
                    ),
                    destination: {
                        ResultView(
                            store: ViewStore(
                                state: store.state.detail,
                                send: store.send,
                                tag: tagResultView
                            )
                        ).equatable()
                    },
                    label: {
                        EmptyView()
                    }
                )
                ZStack {
                    if store.state.searchBar.isFocused {
                        SuggestionsView(
                            store: ViewStore(
                                state: store.state.suggestions,
                                send: store.send,
                                tag: tagSuggestionsAction
                            )
                        )
                        .equatable()
                        .transition(.opacity)
                    } else {
                        VStack {
                            Spacer()
                            Text("Home")
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SubSearchBarView(
                        store: ViewStore(
                            state: store.state.searchBar,
                            send: store.send,
                            tag: tagSearchBarAction
                        )
                    ).equatable()
                }
            }
        }
        .onAppear {
            store.send(.appear)
        }
        .environment(\.openURL, OpenURLAction { url in
            if let query = SubURL.urlToWikilink(url) {
                store.send(.commitQuery(query))
                return .handled
            }
            return .systemAction
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
