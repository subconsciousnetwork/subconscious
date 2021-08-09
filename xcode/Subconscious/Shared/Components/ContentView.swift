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
    case editorSaveCreateSuccess(FileEntry)
    case editorSaveUpdateSuccess(FileEntry)
    case setSuggestions(_ suggestions: SuggestionsModel)
    case warning(_ message: String)
    case info(_ message: String)
}

//  MARK: Tagging functions

func tagDatabaseAction(_ action: DatabaseAction) -> ContentAction {
    .database(action)
}

func tagEditorAction(_ action: EditorAction) -> ContentAction {
    switch action {
    case .cancel:
        return .editorCancel
    case .saveCreateSuccess(let fileEntry):
        return .editorSaveCreateSuccess(fileEntry)
    case .saveUpdateSuccess(let fileEntry):
        return .editorSaveUpdateSuccess(fileEntry)
    default:
        return .editor(action)
    }
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

func tagSearchAction(_ action: EntryListAction) -> ContentAction {
    switch action {
    case .requestEdit(let url):
        return .editorOpenUpdate(url)
    case .activateWikilink(let search):
        return .commitQuery(search)
    default:
        return .search(action)
    }
}

func tagSuggestionsAction(_ action: SuggestionsAction) -> ContentAction {
    switch action {
    case .selectResult(let query):
        return .commitQuery(query)
    case .selectQuery(let query):
        return .setQuery(query)
    case .selectCreate(let query):
        return .editorOpenCreate(query)
    default:
        return .suggestions(action)
    }
}

func tagSuggestionTokensAction(_ action: TextTokenBarAction) -> ContentAction {
    switch action {
    case .select(let text):
        return .commitQuery(text)
    default:
        return .suggestionTokens(action)
    }
}

//  MARK: State
/// Central source of truth for all shared app state
struct ContentModel: Equatable {
    var database = DatabaseModel()
    var searchBar = SubSearchBarModel()
    var search = EntryListModel()
    /// Semi-permanent suggestions that show up as tokens in the search view.
    /// We don't differentiate between types of token, so these are all just strings.
    var suggestionTokens = TextTokenBarModel()
    /// Live-as-you-type suggestions
    var suggestions = SuggestionsModel()
    var editor = EditorModel()
    var isEditorPresented = false
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
    case .editor(let action):
        return updateEditor(
            state: &state.editor,
            action: action,
            environment: environment.io
        ).map(tagEditorAction).eraseToAnyPublisher()
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
    case .search(let action):
        return updateEntryList(
            state: &state.search,
            action: action,
            environment: environment.io
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
        let initialQueryEffect = Just(ContentAction.commitQuery(""))
        let suggestionTokensEffect = environment
            .fetchSuggestionTokens()
            .map({ suggestions in
                ContentAction.suggestionTokens(.setTokens(suggestions))
            })
        let setupDatabaseEffect = Just(ContentAction.database(.setup))
        return Publishers.Merge3(
            initialQueryEffect,
            suggestionTokensEffect,
            setupDatabaseEffect
        ).eraseToAnyPublisher()
    case .setEditorPresented(let isPresented):
        state.isEditorPresented = isPresented
    case .editorCancel:
        let clear = Just(ContentAction.editor(.cancel))
            .delay(
                for: .milliseconds(500),
                scheduler: RunLoop.main
            )
        let close = Just(ContentAction.setEditorPresented(false))
        return Publishers.Merge(
            close,
            clear
        ).eraseToAnyPublisher()
    case .editorOpenCreate(let content):
        let open = Just(ContentAction.setEditorPresented(true))
        let create = Just(ContentAction.editor(.editCreate(content: content)))
        return Publishers.Merge(
            create,
            open
        ).eraseToAnyPublisher()
    case .editorSaveCreateSuccess(let fileEntry):
        let update = Just(ContentAction.editor(.saveCreateSuccess(fileEntry)))
        let close = Just(ContentAction.setEditorPresented(false))
        let search = Just(ContentAction.commitQuery(fileEntry.title))
        return Publishers.Merge3(
            update,
            close,
            search
        ).eraseToAnyPublisher()
    case .editorOpenUpdate(let url):
        let update = Just(ContentAction.editor(.editUpdate(url: url)))
        let open = Just(ContentAction.setEditorPresented(true))
        return Publishers.Merge(
            update,
            open
        ).eraseToAnyPublisher()
    case .editorSaveUpdateSuccess(let fileEntry):
        let update = Just(ContentAction.editor(.saveUpdateSuccess(fileEntry)))
        let close = Just(ContentAction.setEditorPresented(false))
        let search = Just(ContentAction.commitQuery(fileEntry.title))
        return Publishers.Merge3(
            update,
            close,
            search
        ).eraseToAnyPublisher()
    case .commitQuery(let query):
        let commit = Just(ContentAction.searchBar(.commit(query)))
        let suggest = Just(ContentAction.suggestions(.suggest(query)))
        let search = Just(ContentAction.search(.fetch(query)))
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
    let fileManager = FileManager.default
    let documentsUrl: URL
    let databaseUrl: URL
    let logger = Constants.logger
    let database: DatabaseService
    let io: IOService

    init() {
        self.databaseUrl = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("database.sqlite")

        self.documentsUrl = fileManager.documentDirectoryUrl!

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
                    .transition(.opacity.combined(with: .offset(x: 0, y: 24)))
                } else {
                    EntryListView(
                        store: ViewStore(
                            state: store.state.search,
                            send: store.send,
                            tag: tagSearchAction
                        )
                    )
                    .equatable()
                }
            }
            .background(Constants.Color.background)
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
            )
            .equatable()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
