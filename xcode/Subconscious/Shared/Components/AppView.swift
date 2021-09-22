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
    case setDetail(ResultSet)
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
struct AppModel: Updatable {
    var isDatabaseReady = false
    var isDetailShowing = false
    var isDetailLoading = true
    var isSearchBarFocused = false
    var searchBarText = ""
    var suggestions: [Suggestion] = []
    var query = ""
    var editor: EditorModel = EditorModel.empty
    var entry: SubtextDocumentLocation?
    var backlinks: [SubtextDocumentLocation] = []

    //  MARK: Update
    func update(action: AppAction) -> (Self, AnyPublisher<AppAction, Never>) {
        switch action {
        case .appear:
            AppEnvironment.logger.debug(
                "Documents\t\(AppEnvironment.documentURL)"
            )
            let fx = AppEnvironment.database.migrate()
                .map({ success in
                    AppAction.databaseReady(success)
                })
                .catch({ _ in
                    Just(AppAction.rebuildDatabase)
                })
                .eraseToAnyPublisher()
            return (self, fx)
        case let .databaseReady(success):
            var model = self
            model.isDatabaseReady = true
            let sync = AppEnvironment.database.syncDatabase()
                .map({ changes in AppAction.syncSuccess(changes) })
                .catch({ error in
                    Just(.syncFailure(error.localizedDescription))
                })
            let suggestions = Just(AppAction.setSearch(""))
            let fx = Publishers.Merge(suggestions, sync).eraseToAnyPublisher()
            if success.from != success.to {
                AppEnvironment.logger.log(
                    """
                    Migrated database\t\(success.from)->\(success.to)
                    """
                )
            }
            AppEnvironment.logger.log("File sync started")
            return (model, fx)
        case .rebuildDatabase:
            AppEnvironment.logger.warning(
                "Database is broken or has wrong schema. Attempting to rebuild."
            )
            let fx = AppEnvironment.database.delete()
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
            return (self, fx)
        case let .rebuildDatabaseFailure(error):
            AppEnvironment.logger.warning(
                "Could not rebuild database.\t\(error)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .syncSuccess(changes):
            AppEnvironment.logger.debug(
                "File sync finished\t\(changes)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .syncFailure(message):
            AppEnvironment.logger.warning(
                "File sync failed.\t\(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case var .setEditor(editor):
            var model = self
            // Render attributes from markup if text has changed
            if !self.editor.attributedText.isEqual(to: editor.attributedText) {
                editor.render()
            }
            model.editor = editor
            return (model, Empty().eraseToAnyPublisher())
        case let .setDetailShowing(isShowing):
            var model = self
            model.isDetailShowing = isShowing
            return (model, Empty().eraseToAnyPublisher())
        case let .setSearchBarFocus(isFocused):
            var model = self
            model.isSearchBarFocused = isFocused
            return (model, Empty().eraseToAnyPublisher())
        case let .setSearch(text):
            var model = self
            model.searchBarText = text
            let fx = AppEnvironment.database.searchSuggestions(query: text)
                .map({ suggestions in
                    AppAction.setSuggestions(suggestions)
                })
                .catch({ error in
                    Just(.suggestionsFailure(error.localizedDescription))
                })
                .eraseToAnyPublisher()
            return (model, fx)
        case let .setSuggestions(suggestions):
            var model = self
            model.suggestions = suggestions
            return (model, Empty().eraseToAnyPublisher())
        case let .suggestionsFailure(message):
            AppEnvironment.logger.debug(
                "Suggest failed\t\(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .commitSearch(query):
            var model = self
            model.query = query
            model.editor = EditorModel.empty
            model.searchBarText = ""
            model.isSearchBarFocused = false
            model.isDetailShowing = true
            model.isDetailLoading = true

            let suggest = Just(AppAction.setSearch(""))
            let search = AppEnvironment.database.search(query: query)
                .map({ results in
                    AppAction.setDetail(results)
                })
                .catch({ error in
                    Just(AppAction.detailFailure(error.localizedDescription))
                })
            let fx = Publishers.Merge(
                suggest,
                search
            ).eraseToAnyPublisher()

            return (model, fx)
        case let .setDetail(results):
            var model = self
            model.entry = results.entry ?? SubtextDocumentLocation.new(
                directory: AppEnvironment.documentURL,
                document: SubtextDocument(title: query, content: query)
            )
            model.backlinks = results.backlinks
            model.editor = EditorModel(
                markup: results.entry?.document.content ?? self.query
            )
            model.isDetailLoading = false
            return (model, Empty().eraseToAnyPublisher())
        case let .detailFailure(message):
            AppEnvironment.logger.log(
                "Failed to get details for search.\t\(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case .save:
            var model = self
            model.entry?.document.content = model.editor.attributedText.string
            model.editor.isFocused = false
            return (model, Empty().eraseToAnyPublisher())
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
