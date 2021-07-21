//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//

import SwiftUI
import Combine
import os
import Elmo

//  MARK: AppStore typealias
typealias SubconsciousStore = Elmo.Store<AppModel, AppAction, AppEnvironment>


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
    /// Issue and log search
    case commitQuery(_ query: String)
    /// Set live query
    case setQuery(_ text: String)
    /// Re-issue search in order to refresh results
    case refreshQuery
    case setEditorPresented(_ isPresented: Bool)
    case editorUpdateEntry(EntryFile)
    case editorCreateEntry(Entry)
    case setSuggestions(_ suggestions: SuggestionsModel)
    /// Catch create entry success and react to it in other parts of UI
    case createEntrySuccess(EntryFile)
    /// Catch update entry success and react to it in other parts of UI
    case updateEntrySuccess(EntryFile)
    case warning(_ message: String)
    case info(_ message: String)

    static func searchSuggestions(_ query: String) -> AppAction {
        .database(.searchSuggestions(query))
    }

    /// Issue search and log search history
    static func searchAndInsertHistory(_ query: String) -> AppAction {
        .database(.searchAndInsertHistory(query))
    }

    /// Issue search without logging search history
    static func search(_ query: String) -> AppAction {
        .database(.search(query))
    }

    /// Invoke editor in create mode
    /// Currently, this just requires a nil URL. We're differentiating the actions here to make refactoring
    /// easier later, if we end up wanting to further differentiate create vs edit.
    static func invokeEditorCreate(content: String) -> AppAction {
        .invokeEditor(url: nil, content: content)
    }

    static func invokeEditorForEntry(url: URL) -> AppAction {
        //  2021-07-12 Gordon Brander
        //  All single entry reads are currently for the purpose of invoking edit.
        //  In future, we may want to disambiguate different kinds of entry reads.
        //  This might mean refactoring database component into app component.
        //  and using database service directly, rather than through actions.
        .database(.readEntry(url: url))
    }

    static func deleteEntry(url: URL) -> AppAction {
        .database(.deleteEntry(url: url))
    }
}

//  MARK: Tagging functions

func tagDatabaseAction(_ action: DatabaseAction) -> AppAction {
    switch action {
    case .searchSuccess(let results):
        return .search(.setItems(results))
    case .searchSuggestionsSuccess(let results):
        return .setSuggestions(results)
    case .createEntrySuccess(let entry):
        return .createEntrySuccess(entry)
    case .updateEntrySuccess(let entry):
        return .updateEntrySuccess(entry)
    case .readEntrySuccess(let entryFile):
        return .invokeEditor(
            url: entryFile.url,
            content: entryFile.entry.content
        )
    default:
        return .database(action)
    }
}

func tagEditorAction(_ action: EditorAction) -> AppAction {
    switch action {
    case .requestCancel:
        return .setEditorPresented(false)
    case .requestSave(let url, let content):
        if let url = url {
            return .editorUpdateEntry(
                EntryFile(url: url, content: content)
            )
        } else {
            return .editorCreateEntry(Entry(content: content))
        }
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
        return .invokeEditorForEntry(url: url)
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
            return .invokeEditorForEntry(url: url)
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
    var search = EntryListModel([])
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
    case .editorUpdateEntry(let entry):
        let unpresentEditor = Just(AppAction.setEditorPresented(false))
        let updateEntry = Just(AppAction.database(.updateEntry(entry)))
        return Publishers.Merge(
            unpresentEditor,
            updateEntry
        ).eraseToAnyPublisher()
    case .editorCreateEntry(let entry):
        let unpresentEditor = Just(AppAction.setEditorPresented(false))
        let createEntry = Just(
            AppAction.database(.createEntry(entry))
        )
        return Publishers.Merge(
            unpresentEditor,
            createEntry
        ).eraseToAnyPublisher()
    case .commitQuery(let query):
        let commitSearchBar = Just(AppAction.searchBar(.commit(query)))
        let searchSuggestions = Just(AppAction.searchSuggestions(query))
        let searchAndInsertHistory = Just(
            AppAction.searchAndInsertHistory(query)
        )
        return Publishers.Merge3(
            commitSearchBar,
            searchSuggestions,
            searchAndInsertHistory
        ).eraseToAnyPublisher()
    case .refreshQuery:
        /// Reissue search without logging it again
        return Just(
            AppAction.search(state.searchBar.comitted)
        ).eraseToAnyPublisher()
    case .setQuery(let text):
        let setText = Just(AppAction.searchBar(.setText(text)))
        let searchSuggestions = Just(AppAction.searchSuggestions(text))
        return Publishers.Merge(
            setText,
            searchSuggestions
        ).eraseToAnyPublisher()
    case .createEntrySuccess(let entry):
        let success = Just(AppAction.database(.createEntrySuccess(entry)))
        let commit = Just(AppAction.commitQuery(""))
        return Publishers.Merge(
            success,
            commit
        ).eraseToAnyPublisher()
    case .updateEntrySuccess(let entry):
        let success = Just(AppAction.database(.updateEntrySuccess(entry)))
        let refresh = Just(AppAction.refreshQuery)
        return Publishers.Merge(
            success,
            refresh
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


//  MARK: App root view
@main
struct SubconsciousApp: App {
    @StateObject private var store = SubconsciousStore(
        state: .init(),
        reducer: updateApp,
        environment: .init(),
        logger: Logger(
            subsystem: "com.subsconcious.Subconscious",
            category: "store"
        )
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


//  MARK: App Environment
/// Access to external network services and other supporting services
struct AppEnvironment {
    let fileManager = FileManager.default
    let documentsUrl: URL
    let databaseUrl: URL
    let logger = SubConstants.logger
    let database: DatabaseEnvironment

    init() {
        self.databaseUrl = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("database.sqlite")

        self.documentsUrl = fileManager.documentDirectoryUrl!

        self.database = DatabaseEnvironment(
            databaseUrl: databaseUrl,
            documentsUrl: documentsUrl,
            migrations: SubConstants.migrations
        )
    }

    //  FIXME: serves up static suggestions
    func fetchSuggestionTokens() -> Future<[String], Never> {
        Future({ promise in
            let suggestions = [
                "#log",
                "#idea",
                "#pattern",
                "#project",
                "#decision",
                "#quote",
                "#book",
                "#person"
            ]
            promise(.success(suggestions))
        })
    }
}
