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
    case setDetailShowing(Bool)
    case setEditor(EditorModel)
    case setSearchBarText(String)
    case setSearchBarFocus(Bool)
    case suggest(String)
    case suggestFailure(String)
    case setSuggestions([Suggestion])
    case commit(String)
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
    var editor: EditorModel = EditorModel.empty
    var isSearchBarFocused = false
    var searchBarText = ""
    var suggestions: [Suggestion] = []
    var query = ""

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
        case let .setSearchBarText(query):
            return Just(AppAction.suggest(query)).eraseToAnyPublisher()
        case let .suggest(query):
            return AppEnvironment.database.searchSuggestions(query: query)
                .map({ suggestions in
                    AppAction.setSuggestions(suggestions)
                })
                .catch({ error in
                    Just(.suggestFailure(error.localizedDescription))
                })
                .eraseToAnyPublisher()
        case let .suggestFailure(message):
            AppEnvironment.logger.debug(
                """
                Suggest failed\t\(message)
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
        case let .setSearchBarText(text):
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
        case let .commit(query):
            var model = self
            model.query = query
            model.editor = EditorModel.empty
            model.searchBarText = ""
            model.isSearchBarFocused = false
            model.isDetailShowing = true
            model.isDetailLoading = true
            return model
        case
            .appear, .rebuildDatabase, .rebuildDatabaseFailure,
            .syncFailure, .syncSuccess, .suggest, .suggestFailure
        :
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
