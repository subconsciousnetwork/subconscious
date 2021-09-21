//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import os
import Combine

//  MARK: Actions
/// Actions for modifying state
enum AppAction {
    case appear
    case databaseReady(SQLite3Migrations.MigrationSuccess)
    case rebuildDatabase
    case rebuildDatabaseFailure(String)
    case syncSuccess([FileSync.Change])
    case syncFailure(String)
    case setSearch(String)
    case setSearchBarFocus(Bool)
    case setSuggestions([Suggestion])
    case suggestionsFailure(String)
    case commitSearch(String)
    case setDetail(TextFileResults)
    case detailFailure(String)
    case setDetailShowing(Bool)
    case setEditor(EditorModel)
    case save
}

struct EditorModel: Equatable {
    var attributedText: NSAttributedString
    var isFocused: Bool
    var selection: NSRange

    init(
        markup: String,
        isFocused: Bool = false,
        selection: NSRange = NSMakeRange(0, 0)
    ) {
        let dom = Subtext3(markup)
        self.attributedText = dom.renderMarkup(
            url: { text in
                Subtext3.wikilinkToURLString(text)
            }
        )
        self.isFocused = isFocused
        self.selection = selection
    }

    init(
        attributedText: NSAttributedString = NSAttributedString(""),
        isFocused: Bool = false,
        selection: NSRange = NSMakeRange(0, 0)
    ) {
        self.attributedText = attributedText
        self.isFocused = isFocused
        self.selection = selection
    }

    /// Render attributes based on markup
    mutating func render() {
        let dom = Subtext3(self.attributedText.string)
        self.attributedText = dom.renderMarkup(
            url: { text in
                Subtext3.wikilinkToURLString(text)
            }
        )
    }

    // Empty state
    static let empty = EditorModel()
}

//  MARK: Model
struct AppModel: Modelable {
    var isDatabaseReady = false
    var isDetailShowing = false
    var isDetailLoading = true
    var isSearchBarFocused = false
    var searchBarText = ""
    var suggestions: [Suggestion] = []
    var query = ""
    var editor: EditorModel = EditorModel.empty
    var entry: TextFile?
    var backlinks: [TextFile] = []

    //  MARK: Effect
    func effect(action: AppAction) -> Effect<AppAction> {
        switch action {
        case .appear:
            AppEnvironment.logger.debug(
                """
                Documents\t\(AppEnvironment.documentURL)
                """
            )
            return AppEnvironment.database.migrate()
                .map({ success in
                    .databaseReady(success)
                })
                .catch({ _ in
                    Just(.rebuildDatabase)
                })
                .eraseToAnyPublisher()
        case .rebuildDatabase:
            AppEnvironment.logger.warning(
                "Database is broken or has wrong schema. Attempting to rebuild."
            )
            return AppEnvironment.database.delete()
                .flatMap({ _ in
                    AppEnvironment.database.migrate()
                })
                .map({ success in
                    AppAction.databaseReady(success)
                })
                .catch({ error in
                    Just(AppAction.rebuildDatabaseFailure(
                        error.localizedDescription)
                    )
                })
                .eraseToAnyPublisher()
        case let .rebuildDatabaseFailure(error):
            AppEnvironment.logger.warning(
                """
                Could not rebuild database.\t\(error)
                """
            )
            return Empty().eraseToAnyPublisher()
        case let .databaseReady(success):
            let sync = AppEnvironment.database.syncDatabase()
                .map({ changes in AppAction.syncSuccess(changes) })
                .catch({ error in
                    Just(.syncFailure(error.localizedDescription))
                })
            let suggestions = Just(AppAction.setSearch(""))
            if success.from != success.to {
                AppEnvironment.logger.log(
                    """
                    Migrated database\t\(success.from)->\(success.to)
                    """
                )
            }
            AppEnvironment.logger.log("File sync started")
            return Publishers.Merge(
                suggestions,
                sync
            ).eraseToAnyPublisher()
        case let .syncSuccess(changes):
            AppEnvironment.logger.log(
                """
                File sync finished\t\(changes)
                """
            )
            return Empty().eraseToAnyPublisher()
        case let .syncFailure(message):
            AppEnvironment.logger.warning(
                """
                File sync failed.\t\(message)
                """
            )
            return Empty().eraseToAnyPublisher()
        case let .setSearch(query):
            return AppEnvironment.database.searchSuggestions(query: query)
                .map({ suggestions in
                    AppAction.setSuggestions(suggestions)
                })
                .catch({ error in
                    Just(.suggestionsFailure(error.localizedDescription))
                })
                .eraseToAnyPublisher()
        case let .suggestionsFailure(message):
            AppEnvironment.logger.debug(
                """
                Suggest failed\t\(message)
                """
            )
            return Empty().eraseToAnyPublisher()
        case let .commitSearch(query):
            let suggest = Just(AppAction.setSearch(""))
            let search = AppEnvironment.database.search(query: query)
                .map({ results in
                    AppAction.setDetail(results)
                })
                .catch({ error in
                    Just(AppAction.detailFailure(error.localizedDescription))
                })
            return Publishers.Merge(
                suggest,
                search
            ).eraseToAnyPublisher()
        case let .detailFailure(message):
            AppEnvironment.logger.log(
                """
                Failed to get details for search.\t\(message)
                """
            )
            return Empty().eraseToAnyPublisher()
        default:
            return Empty().eraseToAnyPublisher()
        }
    }

    //  MARK: Update
    mutating func update(action: AppAction) {
        switch action {
        case .databaseReady:
            self.isDatabaseReady = true
        case var .setEditor(editor):
            // Render attributes from markup if text has changed
            if !self.editor.attributedText.isEqual(to: editor.attributedText) {
                editor.render()
            }
            self.editor = editor
        case let .setDetailShowing(isShowing):
            self.isDetailShowing = isShowing
        case let .setSearch(text):
            self.searchBarText = text
        case let .setSearchBarFocus(isFocused):
            self.isSearchBarFocused = isFocused
        case let .setSuggestions(suggestions):
            self.suggestions = suggestions
        case let .commitSearch(query):
            self.query = query
            self.editor = EditorModel.empty
            self.searchBarText = ""
            self.isSearchBarFocused = false
            self.isDetailShowing = true
            self.isDetailLoading = true
        case let .setDetail(results):
            self.editor = EditorModel(
                markup: results.entry?.content ?? self.query
            )
            self.backlinks = results.backlinks
            self.isDetailLoading = false
        case .save:
            self.editor.isFocused = false
        case .appear:
            break
        case .rebuildDatabase:
            break
        case .rebuildDatabaseFailure:
            break
        case .syncSuccess:
            break
        case .syncFailure:
            break
        case .suggestionsFailure:
            break
        case .detailFailure:
            break
        }
    }
}

//  MARK: View
struct AppView: View {
    @ObservedObject var store: Store<AppModel>

    var body: some View {
        VStack {
            if store.state.isDatabaseReady {
                AppNavigationView(store: store)
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .onAppear {
            store.send(action: .appear)
        }
        .environment(\.openURL, OpenURLAction { url in
            if let query = Subtext3.urlToWikilink(url) {
                store.send(action: .commitSearch(query))
                return .handled
            }
            return .systemAction
        })
    }
}
