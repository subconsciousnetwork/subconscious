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
}

struct EditorModel: Equatable {
    var attributedText = NSAttributedString("")
    var isFocused = false
    var selection = NSMakeRange(0, 0)

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
            if success.from != success.to {
                AppEnvironment.logger.log(
                    """
                    Migrated database\t\(success.from)->\(success.to)
                    """
                )
            }
            AppEnvironment.logger.log("File sync started")
            return AppEnvironment.database.syncDatabase()
                .map({ changes in .syncSuccess(changes) })
                .catch({ error in
                    Just(.syncFailure(error.localizedDescription))
                })
                .eraseToAnyPublisher()
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
            return AppEnvironment.database.search(query: query)
                .map({ results in
                    AppAction.setDetail(results)
                })
                .catch({ error in
                    Just(AppAction.detailFailure(error.localizedDescription))
                })
                .eraseToAnyPublisher()
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
    func update(action: AppAction) -> Self {
        switch action {
        case .databaseReady:
            var model = self
            model.isDatabaseReady = true
            return model
        case let .setEditor(editor):
            var model = self
            model.editor = editor
            return model
        case let .setDetailShowing(isShowing):
            var model = self
            model.isDetailShowing = isShowing
            return model
        case let .setSearch(text):
            var model = self
            model.searchBarText = text
            return model
        case let .setSearchBarFocus(isFocused):
            var model = self
            model.isSearchBarFocused = isFocused
            return model
        case let .setSuggestions(suggestions):
            var model = self
            model.suggestions = suggestions
            return model
        case let .commitSearch(query):
            var model = self
            model.query = query
            model.editor = EditorModel.empty
            model.searchBarText = ""
            model.isSearchBarFocused = false
            model.isDetailShowing = true
            model.isDetailLoading = true
            return model
        case let .setDetail(results):
            var model = self
            model.editor = EditorModel(
                attributedText: NSAttributedString(
                    string: results.entry?.content ?? model.query
                )
            )
            model.backlinks = results.backlinks
            model.isDetailLoading = false
            return model
        case .appear:
            return self
        case .rebuildDatabase:
            return self
        case .rebuildDatabaseFailure:
            return self
        case .syncSuccess:
            return self
        case .syncFailure:
            return self
        case .suggestionsFailure(_):
            return self
        case .detailFailure(_):
            return self
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
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        AppView(
//
//        )
//    }
//}
