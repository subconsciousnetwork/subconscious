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
    case search(_ action: EntryListAction)
    case suggestionTokens(_ action: TextTokenBarAction)
    /// On view appear
    case appear
    /// Invoke editor with optional URL and content
    case invokeEditor(url: URL?, content: String)
    case commitQuery(_ query: String)
    case setQuery(_ text: String)
    case setEditorPresented(_ isPresented: Bool)
    case setSuggestions(_ suggestions: SuggestionsModel)
    case warning(_ message: String)
    case info(_ message: String)

    static func searchSuggestions(_ query: String) -> AppAction {
        .database(.searchSuggestions(query))
    }

    static func search(_ query: String) -> AppAction {
        .database(.search(query))
    }

    /// Invoke editor in create mode
    /// Currently, this just requires a nil URL. We're differentiating the actions here to make refactoring
    /// easier later, if we end up wanting to further differentiate create vs edit.
    static func invokeEditorCreate(content: String) -> AppAction {
        .invokeEditor(url: nil, content: content)
    }

    static func editDocument(url: URL) -> AppAction {
        //  2021-07-12 Gordon Brander
        //  All document reads are currenlty for the purpose of invoking edit.
        //  In future, we may want to disambiguate different kinds of document reads.
        //  This might mean refactoring database component into app component.
        //  and using database service directly, rather than through actions.
        .database(.readDocument(url: url))
    }
    
    static func updateDocument(
        url: URL?,
        content: String
    ) -> AppAction {
        .database(.updateDocument(url: url, content: content))
    }

    static func deleteDocument(url: URL) -> AppAction {
        .database(.deleteDocument(url: url))
    }
}

//  MARK: Tagging functions

func tagDatabaseAction(_ action: DatabaseAction) -> AppAction {
    switch action {
    case .searchSuccess(let results):
        return .search(.setItems(results))
    case .searchSuggestionsSuccess(let results):
        return .setSuggestions(results)
    case .readDocumentSuccess(let document):
        return .invokeEditor(
            url: document.url,
            content: document.content
        )
    default:
        return .database(action)
    }
}

func tagEditorAction(_ action: EditorAction) -> AppAction {
    switch action {
    case .requestEditorUnpresent:
        return .setEditorPresented(false)
    case .requestSave(let url, let content):
        return .updateDocument(
            url: url,
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

func tagSearchAction(_ action: EntryListAction) -> AppAction {
    switch action {
    case .requestEdit(let url):
        return .editDocument(url: url)
    default:
        return .search(action)
    }
}

func tagSuggestionsAction(_ action: SuggestionsAction) -> AppAction {
    switch action {
    case .selectSearch(let query):
        return .commitQuery(query)
    case .selectAction(let suggestion):
        switch suggestion {
        case .edit(let url, _):
            return .editDocument(url: url)
        case .create(let text):
            return .invokeEditorCreate(content: text)
        }
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
    var search = EntryListModel(documents: [])
    /// Semi-permanent suggestions that show up as tokens in the search view.
    /// We don't differentiate between types of token, so these are all just strings.
    var suggestionTokens = TextTokenBarModel()
    /// Live-as-you-type suggestions
    var suggestions = SuggestionsModel()
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
            environment: environment.logger
        ).map(tagEditorAction).eraseToAnyPublisher()
    case .searchBar(let action):
        return updateSubSearchBar(
            state: &state.searchBar,
            action: action
        ).map(tagSearchBarAction).eraseToAnyPublisher()
    case .search(let action):
        return updateEntryList(
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
    case .invokeEditor(let url, let content):
        let edit = Just(
            AppAction.editor(.edit(url: url, content: content))
        )
        let presentEditor = Just(AppAction.setEditorPresented(true))
        return Publishers.Merge(
            edit,
            presentEditor
        ).eraseToAnyPublisher()
    case .setEditorPresented(let isPresented):
        state.isEditorPresented = isPresented
    case .commitQuery(let query):
        let searchBarEffect = updateSubSearchBar(
            state: &state.searchBar,
            action: .commit(query)
        ).map(tagSearchBarAction)

        let suggestionsEffect = Just(AppAction.searchSuggestions(query))
        let databaseSearchEffect = Just(AppAction.search(query))
        
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
