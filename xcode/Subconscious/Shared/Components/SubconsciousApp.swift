//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//

import SwiftUI
import Combine

//  MARK: AppStore typealias
typealias AppStore = Store<AppModel, AppAction, AppEnvironment>


//  MARK: App Actions
/// Actions that may be taken on the Store
enum AppAction {
    /// Database actions
    case database(_ action: DatabaseAction)
    /// Editor actions
    case editor(_ action: EditorAction)
    /// Search Bar actions
    case searchBar(_ action: SubSearchBarAction)
    /// Search results actions
    case search(_ action: SearchAction)
    case suggestionTokens(_ action: TextTokenBarAction)
    /// On view appear
    case appear
    case edit(_ document: SubconsciousDocument)
    case commitQuery(_ query: String)
    case setQuery(_ text: String)
    case setEditorPresented(_ isPresented: Bool)
    case setSuggestions(_ suggestions: [Suggestion])
    case warning(_ message: String)
    case info(_ message: String)

    static func searchSuggestions(_ query: String) -> AppAction {
        .database(.searchSuggestions(query))
    }

    static func writeDocumentByTitle(
        title: String,
        content: String
    ) -> AppAction {
        .database(.writeDocumentByTitle(title: title, content: content))
    }

    static func deleteDocument(url: URL) -> AppAction {
        .database(.deleteDocument(url: url))
    }
}

//  MARK: Tagging functions

func tagDatabaseAction(_ action: DatabaseAction) -> AppAction {
    switch action {
    case .searchSuccess(let results):
        return .search(
            .setItems(
                results.map({ textFile in
                    SubconsciousDocument(
                        title: textFile.url.stem,
                        markup: textFile.content
                    )
                })
            )
        )
    case .searchSuggestionsSuccess(let results):
        return .setSuggestions(results)
    default:
        return .database(action)
    }
}

func tagEditorAction(_ action: EditorAction) -> AppAction {
    switch action {
    case .requestEditorUnpresent:
        return .setEditorPresented(false)
    case .requestSave(let title, let content):
        return .writeDocumentByTitle(
            title: title,
            content: content
        )
    default:
        return .editor(action)
    }
}

func tagSearchBarAction(_ action: SubSearchBarAction) -> AppAction {
    switch action {
    case .commit(let text):
        return .commitQuery(text)
    case .setText(let text):
        return .setQuery(text)
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

func tagSuggestionListAction(_ action: SuggestionsAction) -> AppAction {
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
    var database = DatabaseModel()
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
    case .database(let action):
        return updateDatabase(
            state: &state.database,
            action: action,
            environment: environment.database
        ).map(tagDatabaseAction).eraseToAnyPublisher()
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
            environment: environment.logger
        ).map(tagSearchAction).eraseToAnyPublisher()
    case .suggestionTokens(let action):
        return updateTextTokenBar(
            state: &state.suggestionTokens,
            action: action,
            environment: environment.logger
        ).map(tagSuggestionTokensAction).eraseToAnyPublisher()
    case .appear:
        environment.logger.info(
            """
            User Directory:
            \(environment.documentsUrl.absoluteString)
            """
        )
        let initialQueryEffect = Just(AppAction.commitQuery(""))
        let suggestionTokensEffect = environment
            .fetchSuggestionTokens()
            .map({ suggestions in
                AppAction.suggestionTokens(.setTokens(suggestions))
            })
        let setupDatabaseEffect = Just(AppAction.database(.setup))
        return Publishers.Merge3(
            initialQueryEffect,
            suggestionTokensEffect,
            setupDatabaseEffect
        ).eraseToAnyPublisher()
    case .edit(let document):
        state.isEditorPresented = true
        return Just(
            .editor(
                .edit(
                    title: document.title,
                    content: document.content.description
                )
            )
        ).eraseToAnyPublisher()
    case .setEditorPresented(let isPresented):
        state.isEditorPresented = isPresented
    case .commitQuery(let query):
        let searchBarEffect = updateSubSearchBar(
            state: &state.searchBar,
            action: .commit(query)
        ).map(tagSearchBarAction)

        let suggestionsEffect = environment
            .fetchSuggestions(query: query)
            .map(AppAction.setSuggestions)

        let databaseSearchEffect = Just(AppAction.database(.search(query)))
        
        return Publishers.Merge3(
            searchBarEffect,
            suggestionsEffect,
            databaseSearchEffect
        ).eraseToAnyPublisher()
    case .setQuery(let text):
        let searchBarEffect = updateSubSearchBar(
            state: &state.searchBar,
            action: .setText(text)
        ).map(tagSearchBarAction)

        let suggestionsEffect = Just(AppAction.searchSuggestions(text))

        return Publishers.Merge(
            searchBarEffect,
            suggestionsEffect
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


//  MARK: App main View
@main
struct SubconsciousApp: App {
    @StateObject private var store: AppStore = AppStore(
        state: .init(),
        reducer: updateApp,
        environment: .init()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(
                store: ViewStore(
                    state: store.state,
                    send: store.send
                )
            ).equatable()
        }
    }
}
