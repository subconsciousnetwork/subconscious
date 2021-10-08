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
    case noop
    case appear
    case openURL(URL)
    case openEditorURL(url: URL, range: NSRange)

    // Database
    case databaseReady(SQLite3Migrations.MigrationSuccess)
    case rebuildDatabase
    case rebuildDatabaseFailure(String)
    case syncSuccess([FileSync.Change])
    case syncFailure(String)

    // Search
    case setSearch(String)
    case commitSearch(String)

    // Search suggestions
    case setSuggestions([Suggestion])
    case suggestionsFailure(String)

    // Detail
    case setDetail(ResultSet)
    case detailFailure(String)
    case setDetailShowing(Bool)

    // Editor
    case setEditorAttributedText(NSAttributedString)
    case setEditorSelection(NSRange)
    case setEditorFocus(Bool)

    // Link suggestions
    case setLinkSheetPresented(Bool)
    case setLinkSearchFocus(Bool)
    case setLinkSearchText(String)
    case commitLinkSearch(String)
    case setLinkSuggestions([Suggestion])
    case linkSuggestionsFailure(String)

    // Saving entries
    case save
    case saveSuccess(URL)
    case saveFailure(
        url: URL,
        message: String
    )
}

//  MARK: Model
struct AppModel: Updatable {
    // Is database connected and migrated?
    var isDatabaseReady = false
    // Is the detail view (edit and details for an entry) showing?
    var isDetailShowing = false
    // Live search bar text
    var searchBarText = ""
    // Committed search bar text
    var query = ""
    // Main search suggestions
    var suggestions: [Suggestion] = []
    var isEditorFocused = false
    var editorAttributedText = NSAttributedString("")
    // Editor selection corresponds with `editorAttributedText`
    var editorSelection = NSMakeRange(0, 0)
    // The URL for the currently active entry
    var entryURL: URL?
    // Backlinks to the currently active entry
    var backlinks: [TextFile] = []

    // Link suggestions for modal and bar in edit mode
    var isLinkSheetPresented = false
    var isLinkSearchFocused = false
    var linkSearchText = ""
    var linkSearchQuery = ""
    var linkSuggestions: [Suggestion] = []

    // Set all editor properties to initial values
    static func resetEditor(_ model: inout Self) {
        model.editorAttributedText = NSAttributedString("")
        model.editorSelection = NSMakeRange(0, 0)
        model.isEditorFocused = false
    }

    static func renderMarkup(
        markup: String,
        selection: NSRange
    ) -> NSAttributedString {
        Subtext4(
            markup: markup,
            range: selection
        ).renderMarkup(url: Slashlink.slashlinkToURLString)
    }

    //  MARK: Update
    func update(action: AppAction) -> (Self, AnyPublisher<AppAction, Never>) {
        switch action {
        case .noop:
            return (self, Empty().eraseToAnyPublisher())
        case .appear:
            AppEnvironment.logger.debug(
                "Documents: \(AppEnvironment.documentURL)"
            )
            let fx = AppEnvironment.database.migrate().map({ success in
                AppAction.databaseReady(success)
            }).catch({ _ in
                Just(AppAction.rebuildDatabase)
            }).eraseToAnyPublisher()
            return (self, fx)
        case let .openURL(url):
            let fx = Deferred<Just<AppAction>>(createPublisher: {
                UIApplication.shared.open(url)
                return Just(.noop)
            }).eraseToAnyPublisher()
            return (self, fx)
        case let .openEditorURL(url, range):
            // Don't follow links while editing. Instead, select the link.
            //
            // When editing, you usually don't want to follow a link, you
            // want to tap into it to edit it. Also, we don't want to follow a
            // link in the middle of an edit and lose changes.
            //
            // Other approaches we could take in future:
            // - Save before following
            // - Have a disclosure step before following (like Google Docs)
            // For now, I think this is the best approach.
            //
            // 2021-09-23 Gordon Brander
            if self.isEditorFocused {
                let fx = Just(
                    AppAction.setEditorSelection(range)
                ).eraseToAnyPublisher()
                return (self, fx)
            } else {
                if let query = Slashlink.urlToSlashlinkString(
                    url
                ) {
                    // If this is a Subtext URL, then commit a search for the
                    // corresponding query
                    let fx = Just(
                        AppAction.commitSearch(query)
                    ).eraseToAnyPublisher()
                    return (self, fx)
                } else {
                    // Otherwise open the URL using the shared system
                    // open function.
                    let fx = Deferred<Just<AppAction>>(createPublisher: {
                        UIApplication.shared.open(url)
                        return Just(.noop)
                    }).eraseToAnyPublisher()
                    return (self, fx)
                }
            }
        case let .databaseReady(success):
            var model = self
            model.isDatabaseReady = true
            let sync = AppEnvironment.database.syncDatabase().map({ changes in
                AppAction.syncSuccess(changes)
            }).catch({ error in
                Just(.syncFailure(error.localizedDescription))
            })
            let suggestions = Just(AppAction.setSearch(""))
            let fx = Publishers.Merge(
                suggestions, sync
            ).eraseToAnyPublisher()
            if success.from != success.to {
                AppEnvironment.logger.log(
                    "Migrated database: \(success.from)->\(success.to)"
                )
            }
            AppEnvironment.logger.log("File sync started")
            return (model, fx)
        case .rebuildDatabase:
            AppEnvironment.logger.warning(
                "Database is broken or has wrong schema. Attempting to rebuild."
            )
            let fx = AppEnvironment.database.delete().flatMap({ _ in
                AppEnvironment.database.migrate()
            }).map({ success in
                AppAction.databaseReady(success)
            }).catch({ error in
                Just(AppAction.rebuildDatabaseFailure(
                    error.localizedDescription)
                )
            }).eraseToAnyPublisher()
            return (self, fx)
        case let .rebuildDatabaseFailure(error):
            AppEnvironment.logger.warning(
                "Could not rebuild database: \(error)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .syncSuccess(changes):
            AppEnvironment.logger.debug(
                "File sync finished: \(changes)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .syncFailure(message):
            AppEnvironment.logger.warning(
                "File sync failed: \(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .setEditorAttributedText(attributedText):
            var model = self
            // Render attributes from markup if text has changed
            if !self.editorAttributedText.isEqual(to: attributedText) {
                // Rerender attributes from markup, then assign to
                // model.
                model.editorAttributedText = Self.renderMarkup(
                    markup: attributedText.string,
                    selection: model.editorSelection
                )
            }
            return (model, Empty().eraseToAnyPublisher())
        case let .setEditorSelection(range):
            var model = self
            model.editorSelection = range
            return (model, Empty().eraseToAnyPublisher())
        case let .setEditorFocus(isFocused):
            var model = self
            model.isEditorFocused = isFocused
            return (model, Empty().eraseToAnyPublisher())
        case let .setDetailShowing(isShowing):
            var model = self
            model.isDetailShowing = isShowing
            if isShowing == false {
                model.isEditorFocused = false
            }
            return (model, Empty().eraseToAnyPublisher())
        case let .setSearch(text):
            var model = self
            model.searchBarText = text
            let fx = AppEnvironment.database.searchSuggestions(
                query: text
            ).map({ suggestions in
                AppAction.setSuggestions(suggestions)
            }).catch({ error in
                Just(.suggestionsFailure(error.localizedDescription))
            }).eraseToAnyPublisher()
            return (model, fx)
        case let .setSuggestions(suggestions):
            var model = self
            model.suggestions = suggestions
            return (model, Empty().eraseToAnyPublisher())
        case let .suggestionsFailure(message):
            AppEnvironment.logger.debug(
                "Suggest failed: \(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .commitSearch(query):
            var model = self
            Self.resetEditor(&model)
            model.query = query
            model.entryURL = nil
            model.searchBarText = ""
            model.isDetailShowing = true

            let suggest = Just(AppAction.setSearch(""))
            let search = AppEnvironment.database.search(
                slug: query
            ).map({ results in
                AppAction.setDetail(results)
            }).catch({ error in
                Just(AppAction.detailFailure(error.localizedDescription))
            })
            let fx = Publishers.Merge(
                suggest,
                search
            ).eraseToAnyPublisher()

            return (model, fx)
        case let .setDetail(results):
            var model = self
            model.backlinks = results.backlinks
            let entryURL = results.entry?.url
            model.entryURL = entryURL ?? AppEnvironment.database.findUniqueURL(
                name: results.query
            )
            model.editorAttributedText = Self.renderMarkup(
                markup: results.entry?.content ?? results.query,
                selection: model.editorSelection
            )
            return (model, Empty().eraseToAnyPublisher())
        case let .detailFailure(message):
            AppEnvironment.logger.log(
                "Failed to get details for search: \(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .setLinkSheetPresented(isPresented):
            var model = self
            model.isLinkSheetPresented = isPresented
            return (model, Empty().eraseToAnyPublisher())
        case let .setLinkSearchFocus(isFocused):
            var model = self
            model.isLinkSearchFocused = isFocused
            return (model, Empty().eraseToAnyPublisher())
        case let .setLinkSearchText(text):
            var model = self
            model.linkSearchText = text

            let fx = AppEnvironment.database.searchSuggestions(
                query: text
            ).map({ suggestions in
                AppAction.setLinkSuggestions(suggestions)
            }).catch({ error in
                Just(.linkSuggestionsFailure(error.localizedDescription))
            }).eraseToAnyPublisher()

            return (model, fx)
        case let .commitLinkSearch(text):
            var model = self
            model.linkSearchQuery = text
            model.linkSearchText = ""
            model.isLinkSearchFocused = false
            model.isLinkSheetPresented = false
            return (model, Empty().eraseToAnyPublisher())
        case let .setLinkSuggestions(suggestions):
            var model = self
            model.linkSuggestions = suggestions
            return (model, Empty().eraseToAnyPublisher())
        case let .linkSuggestionsFailure(message):
            AppEnvironment.logger.debug(
                "Link suggest failed: \(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case .save:
            var model = self
            model.isEditorFocused = false
            if let entryURL = self.entryURL {
                let fx = AppEnvironment.database.writeEntry(
                    url: entryURL,
                    content: model.editorAttributedText.string
                ).map({ _ in
                    AppAction.saveSuccess(entryURL)
                }).catch({ error in
                    Just(
                        AppAction.saveFailure(
                            url: entryURL,
                            message: error.localizedDescription
                        )
                    )
                }).eraseToAnyPublisher()
                return (model, fx)
            } else {
                AppEnvironment.logger.warning(
                    """
                    Could not save. No URL set for entry.
                    It should not be possible to reach this state.
                    """
                )
                return (model, Empty().eraseToAnyPublisher())
            }
        case let .saveSuccess(url):
            AppEnvironment.logger.debug(
                "Saved entry \(url)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .saveFailure(url, message):
            //  TODO: show user a "try again" banner
            AppEnvironment.logger.warning(
                "Save failed for entry (\(url)) with error: \(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
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
            store.send(action: .openURL(url))
            return .handled
        })
    }
}
