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
    case result(ResultView.Action)
    /// On view appear
    case appear
    /// Issue and log search
    case commitQuery(String)
    /// Set live query
    case setQuery(String)
    case setSuggestions(_ suggestions: SuggestionsModel)
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
        return .result(action)
    }
}

//  MARK: State
/// Central source of truth for all shared app state
struct ContentModel: Equatable {
    var database = DatabaseModel()
    var searchBar = SubSearchBarModel()
    var result = ResultView.Model()
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
    case .result(let action):
        return ResultView.update(
            state: &state.result,
            action: action,
            environment: environment.io
        ).map(tagResultView).eraseToAnyPublisher()
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
        let search = Just(ContentAction.result(.search(query)))
        return Publishers.Merge3(
            commit,
            suggest,
            search
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
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(
                    action: {
                        store.send(.commitQuery(""))
                    },
                    label: {
                        IconView(image: Image(systemName: "chevron.left"))
                    }
                )
                .padding(.leading, 8)
                .disabled(store.state.searchBar.comitted.isEmpty)
                SubSearchBarView(
                    store: ViewStore(
                        state: store.state.searchBar,
                        send: store.send,
                        tag: tagSearchBarAction
                    )
                ).equatable()
            }
            Divider()
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
                    if !store.state.searchBar.comitted.isWhitespace {
                        ResultView(
                            store: ViewStore(
                                state: store.state.result,
                                send: store.send,
                                tag: tagResultView
                            )
                        ).equatable()
                    } else {
                        VStack {
                            Spacer()
                            Text("Home")
                            Spacer()
                        }
                    }
                }
            }
            .background(Constants.Color.background)
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
