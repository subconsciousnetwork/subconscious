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
    /// Search suggestions actions
    case suggestions(SuggestionsAction)
    /// Search results actions
    case search(_ action: EntryListAction)
    case suggestionTokens(_ action: TextTokenBarAction)
    /// On view appear
    case appear
    /// Issue and log search
    case commitQuery(_ query: String)
    /// Set live query
    case setQuery(_ text: String)
    case setEditorPresented(_ isPresented: Bool)
    case editorOpenCreate(String)
    case editorOpenUpdate(URL)
    case editorCancel
    case editorSaveCreateSuccess(EntryFile)
    case editorSaveUpdateSuccess(EntryFile)
    case setSuggestions(_ suggestions: SuggestionsModel)
    case warning(_ message: String)
    case info(_ message: String)

    /// Issue search and log search history
    static func searchAndInsertHistory(_ query: String) -> AppAction {
        .database(.searchAndInsertHistory(query))
    }

    /// Issue search without logging search history
    static func search(_ query: String) -> AppAction {
        .database(.search(query))
    }
}

//  MARK: Tagging functions

func tagDatabaseAction(_ action: DatabaseAction) -> AppAction {
    switch action {
    case .searchSuccess(let results):
        return .search(.setItems(results))
    default:
        return .database(action)
    }
}

func tagEditorAction(_ action: EditorAction) -> AppAction {
    switch action {
    case .cancel:
        return .editorCancel
    case .saveCreateSuccess(let entryFile):
        return .editorSaveCreateSuccess(entryFile)
    case .saveUpdateSuccess(let entryFile):
        return .editorSaveUpdateSuccess(entryFile)
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
        return .editorOpenUpdate(url)
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
            return .editorOpenUpdate(url)
        case .create(let text):
            return .editorOpenCreate(text)
        }
    default:
        return .suggestions(action)
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
            environment: environment.editor
        ).map(tagEditorAction).eraseToAnyPublisher()
    case .searchBar(let action):
        return updateSubSearchBar(
            state: &state.searchBar,
            action: action
        ).map(tagSearchBarAction).eraseToAnyPublisher()
    case .suggestions(let action):
        return updateSuggestions(
            state: &state.suggestions,
            action: action,
            environment: environment.suggestions
        ).map(tagSuggestionsAction).eraseToAnyPublisher()
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
    case .setEditorPresented(let isPresented):
        state.isEditorPresented = isPresented
    case .editorCancel:
        let clear = Just(AppAction.editor(.cancel))
            .delay(
                for: .milliseconds(500),
                scheduler: RunLoop.main
            )
        let close = Just(AppAction.setEditorPresented(false))
        return Publishers.Merge(
            close,
            clear
        ).eraseToAnyPublisher()
    case .editorOpenCreate(let content):
        let open = Just(AppAction.setEditorPresented(true))
        let create = Just(AppAction.editor(.editCreate(content: content)))
        return Publishers.Merge(
            create,
            open
        ).eraseToAnyPublisher()
    case .editorSaveCreateSuccess(let entryFile):
        let update = Just(AppAction.editor(.saveCreateSuccess(entryFile)))
        let close = Just(AppAction.setEditorPresented(false))
        let search = Just(AppAction.commitQuery(entryFile.entry.title))
        return Publishers.Merge3(
            update,
            close,
            search
        ).eraseToAnyPublisher()
    case .editorOpenUpdate(let url):
        let update = Just(AppAction.editor(.editUpdate(url: url)))
        let open = Just(AppAction.setEditorPresented(true))
        return Publishers.Merge(
            update,
            open
        ).eraseToAnyPublisher()
    case .editorSaveUpdateSuccess(let entryFile):
        let update = Just(AppAction.editor(.saveUpdateSuccess(entryFile)))
        let close = Just(AppAction.setEditorPresented(false))
        let search = Just(AppAction.commitQuery(entryFile.entry.title))
        return Publishers.Merge3(
            update,
            close,
            search
        ).eraseToAnyPublisher()
    case .commitQuery(let query):
        let commit = Just(AppAction.searchBar(.commit(query)))
        let suggest = Just(AppAction.suggestions(.suggest(query)))
        let searchAndInsertHistory = Just(
            AppAction.searchAndInsertHistory(query)
        )
        return Publishers.Merge3(
            commit,
            suggest,
            searchAndInsertHistory
        ).eraseToAnyPublisher()
    case .setQuery(let query):
        let setText = Just(AppAction.searchBar(.setText(query)))
        let suggest = Just(AppAction.suggestions(.suggest(query)))
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


//  MARK: App root view
@main
struct SubconsciousApp: App {
    @StateObject private var store = SubconsciousStore(
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


//  MARK: App Environment
/// Access to external network services and other supporting services
struct AppEnvironment {
    let fileManager = FileManager.default
    let documentsUrl: URL
    let databaseUrl: URL
    let logger = SubConstants.logger
    let database: DatabaseEnvironment
    let editor: EditorService
    let suggestions: SuggestionsService

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

        self.editor = EditorService(
            logger: logger,
            database: database
        )

        self.suggestions = SuggestionsService(
            logger: logger,
            database: database
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
