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

    // Focus state for TextFields, TextViews, etc
    case setFocus(AppModel.Focus?)

    // Database
    case databaseReady(SQLite3Migrations.MigrationSuccess)
    case rebuildDatabase
    case rebuildDatabaseFailure(String)
    case syncSuccess([FileSync.Change])
    case syncFailure(String)

    // List entries
    case listRecent
    case setRecent([EntryStub])
    case listRecentFailure(String)

    // Delete entries
    case confirmDelete(String)
    case setConfirmDeleteShowing(Bool)
    case deleteEntry(String)
    case deleteEntrySuccess(String)
    case deleteEntryFailure(String)

    // Search
    case setSearch(String)
    case showSearch
    case hideSearch
    // Commit a search with query and slug (typically via suggestion)
    case commit(query: String, slug: String)

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

    // Link suggestions
    case setLinkSheetPresented(Bool)
    case setLinkSearch(String)
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

    /// Create a "commit" action with only a query and no slug.
    /// Used as a shorthand for search commits that aren't issued from suggestions.
    static func commitSearch(query: String) -> Self {
        AppAction.commit(
            query: query,
            // Since we don't have a slug, derive slug from query
            slug: Slashlink.slugify(query)
        )
    }
}

struct AppUpdate {
    /// Set all editor properties to initial values
    static func resetEditor(_ model: inout AppModel) {
        model.editorAttributedText = NSAttributedString("")
        model.editorSelection = NSMakeRange(0, 0)
        model.focus = nil
    }

    static func renderMarkup(
        markup: String
    ) -> NSAttributedString {
        Subtext(markup: markup)
            .renderMarkup(url: Slashlink.slashlinkToURLString)
    }

    private static func appear(state: AppModel) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.debug(
            "Documents: \(AppEnvironment.documentURL)"
        )
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .migrate()
            .map({ success in
                AppAction.databaseReady(success)
            })
            .catch({ _ in
                Just(AppAction.rebuildDatabase)
            })
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    private static func openEditorURL(
        state: AppModel,
        url: URL,
        range: NSRange
    ) -> Change<AppModel, AppAction> {
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
        if state.focus == .editor {
            let fx: AnyPublisher<AppAction, Never> = Just(
                AppAction.setEditorSelection(range)
            ).eraseToAnyPublisher()
            return Change(state: state, fx: fx)
        } else {
            if Slashlink.isSlashlinkURL(url) {
                // If this is a Subtext URL, then commit a search for the
                // corresponding query
                let fx: AnyPublisher<AppAction, Never> = Just(
                    AppAction.commitSearch(
                        query: Slashlink.urlToProse(url)
                    )
                ).eraseToAnyPublisher()
                return Change(state: state, fx: fx)
            } else {
                UIApplication.shared.open(url)
                return Change(state: state)
            }
        }
    }

    private static func databaseReady(
        state: AppModel,
        success: SQLite3Migrations.MigrationSuccess
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.isDatabaseReady = true
        let sync = AppEnvironment.database.syncDatabase()
            .map({ changes in
                AppAction.syncSuccess(changes)
            })
            .catch({ error in
                Just(.syncFailure(error.localizedDescription))
            })
        let suggestions = Just(AppAction.setSearch(""))
        let linkSuggestions = Just(AppAction.setLinkSearch(""))
        let recent = Just(AppAction.listRecent)
        let fx: AnyPublisher<AppAction, Never> = Publishers.Merge4(
            suggestions,
            linkSuggestions,
            recent,
            sync
        ).eraseToAnyPublisher()
        if success.from != success.to {
            AppEnvironment.logger.log(
                "Migrated database: \(success.from)->\(success.to)"
            )
        }
        AppEnvironment.logger.log("File sync started")
        return Change(state: model, fx: fx)
    }

    private static func rebuildDatabase(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.warning(
            "Database is broken or has wrong schema. Attempting to rebuild."
        )
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .delete()
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
        return Change(state: state, fx: fx)
    }

    private static func listRecent(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .listRecentEntries()
            .map({ entries in
                AppAction.setRecent(entries)
            })
            .catch({ error in
                Just(
                    .listRecentFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    private static func deleteEntry(
        state: AppModel,
        slug: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        if let index = model.recent.firstIndex(
            where: { stub in stub.id == slug }
        ) {
            model.recent.remove(at: index)
            let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
                .deleteEntry(slug: slug)
                .map({ _ in
                    AppAction.deleteEntrySuccess(slug)
                })
                .catch({ error in
                    Just(
                        AppAction.deleteEntryFailure(
                            error.localizedDescription
                        )
                    )
                })
                .eraseToAnyPublisher()
            return Change(state: model, fx: fx)
        } else {
            AppEnvironment.logger.log(
                "Failed to delete entry. No such id: \(slug)"
            )
            return Change(state: model)
        }
    }

    private static func deleteEntrySuccess(
        state: AppModel,
        slug: String
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.log("Deleted entry: \(slug)")
        //  Refresh lists in search fields after delete.
        //  This ensures they don't show the deleted entry.
        let fx: AnyPublisher<AppAction, Never> = Publishers.Merge(
            Just(AppAction.setSearch("")),
            Just(AppAction.setLinkSearch(""))
        ).eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    private static func setSearch(
        state: AppModel,
        text: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.searchText = text
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .searchSuggestions(query: text)
            .map({ suggestions in
                AppAction.setSuggestions(suggestions)
            })
            .catch({ error in
                Just(.suggestionsFailure(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Change(state: model, fx: fx)
    }

    private static func commit(state: AppModel, query: String, slug: String) -> Change<AppModel, AppAction> {
        var model = state
        resetEditor(&model)
        model.entryURL = nil
        model.searchText = ""
        model.isSearchShowing = false
        model.isDetailShowing = true

        let suggest = Just(AppAction.setSearch(""))
        let search = AppEnvironment.database.search(
            query: query,
            slug: slug
        ).map({ results in
            AppAction.setDetail(results)
        }).catch({ error in
            Just(AppAction.detailFailure(error.localizedDescription))
        })
        let fx: AnyPublisher<AppAction, Never> = Publishers.Merge(
            suggest,
            search
        ).eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }

    private static func setLinkSearch(
        state: AppModel,
        text: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.linkSearchText = text

        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .searchSuggestions(
                query: text
            )
            .map({ suggestions in
                AppAction.setLinkSuggestions(suggestions)
            })
            .catch({ error in
                Just(.linkSuggestionsFailure(error.localizedDescription))
            })
            .eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }

    private static func commitLinkSearch(state: AppModel, text: String) -> Change<AppModel, AppAction> {
        var model = state
        if let range = Range(
            model.editorSelection,
            in: state.editorAttributedText.string
        ) {
            // Replace selected range with committed link search text.
            let markup = state.editorAttributedText.string
                .replacingCharacters(
                    in: range,
                    with: text
                )
            // Re-render and assign
            model.editorAttributedText = renderMarkup(markup: markup)
            // Find inserted range by searching for our inserted text
            // AFTER the cursor position.
            if let insertedRange = markup.range(
                of: text,
                range: range.lowerBound..<markup.endIndex
            ) {
                // Convert Range to NSRange of editorAttributedText,
                // assign to editorSelection.
                model.editorSelection = NSRange(
                    insertedRange,
                    in: markup
                )
            }
        }
        model.linkSearchQuery = text
        model.linkSearchText = ""
        model.focus = nil
        model.isLinkSheetPresented = false
        return Change(state: model)
    }

    private static func save(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.focus = nil
        if let entryURL = model.entryURL {
            // Parse editorAttributedText to entry.
            // TODO refactor model to store entry instead of attributedText.
            let entry = SubtextFile(
                url: entryURL,
                content: model.editorAttributedText.string
            )
            let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
                .writeEntry(
                    entry: entry
                )
                .map({ _ in
                    AppAction.saveSuccess(entryURL)
                })
                .catch({ error in
                    Just(
                        AppAction.saveFailure(
                            url: entryURL,
                            message: error.localizedDescription
                        )
                    )
                })
                .eraseToAnyPublisher()
            return Change(state: model, fx: fx)
        } else {
            AppEnvironment.logger.warning(
                """
                Could not save. No URL set for entry.
                It should not be possible to reach this state.
                """
            )
            return Change(state: model)
        }
    }

    //  MARK: Update
    static func update(
        state: AppModel,
        action: AppAction
    ) -> Change<AppModel, AppAction> {
        switch action {
        case .noop:
            return Change(state: state)
        case .appear:
            return appear(state: state)
        case let .openURL(url):
            UIApplication.shared.open(url)
            return Change(state: state)
        case let .openEditorURL(url, range):
            return openEditorURL(state: state, url: url, range: range)
        case let .setFocus(focus):
            var model = state
            model.focus = focus
            return Change(state: model)
        case let .databaseReady(success):
            return databaseReady(state: state, success: success)
        case .rebuildDatabase:
            return rebuildDatabase(state: state)
        case let .rebuildDatabaseFailure(error):
            AppEnvironment.logger.warning(
                "Could not rebuild database: \(error)"
            )
            return Change(state: state)
        case let .syncSuccess(changes):
            AppEnvironment.logger.debug(
                "File sync finished: \(changes)"
            )
            return Change(state: state)
        case let .syncFailure(message):
            AppEnvironment.logger.warning(
                "File sync failed: \(message)"
            )
            return Change(state: state)
        case .listRecent:
            return listRecent(state: state)
        case let .setRecent(entries):
            var model = state
            model.recent = entries
            return Change(state: model)
        case let .listRecentFailure(error):
            AppEnvironment.logger.warning(
                "Failed to list recent entries: \(error)"
            )
            return Change(state: state)
        case let .confirmDelete(slug):
            var model = state
            model.entryToDelete = slug
            model.isConfirmDeleteShowing = true
            return Change(state: model)
        case let .setConfirmDeleteShowing(isShowing):
            var model = state
            model.isConfirmDeleteShowing = isShowing
            // Reset entry to delete if we're dismissing the confirmation
            // dialog.
            if isShowing == false {
                model.entryToDelete = nil
            }
            return Change(state: model)
        case let .deleteEntry(slug):
            return deleteEntry(state: state, slug: slug)
        case let .deleteEntrySuccess(slug):
            return deleteEntrySuccess(state: state, slug: slug)
        case let .deleteEntryFailure(error):
            AppEnvironment.logger.log("Failed to delete entry: \(error)")
            return Change(state: state)
        case let .setEditorAttributedText(attributedText):
            var model = state
            // Render attributes from markup if text has changed
            if !state.editorAttributedText.isEqual(to: attributedText) {
                // Rerender attributes from markup, then assign to
                // model.
                model.editorAttributedText = renderMarkup(
                    markup: attributedText.string
                )
            }
            return Change(state: model)
        case let .setEditorSelection(range):
            var model = state
            model.editorSelection = range
            return Change(state: model)
        case let .setDetailShowing(isShowing):
            var model = state
            model.isDetailShowing = isShowing
            if isShowing == false {
                model.focus = nil
            }
            return Change(state: model)
        case let .setSearch(text):
            return setSearch(state: state, text: text)
        case .showSearch:
            var model = state
            model.isSearchShowing = true
            model.searchText = ""
            model.focus = .search
            return Change(state: model)
        case .hideSearch:
            var model = state
            model.isSearchShowing = false
            model.searchText = ""
            model.focus = nil
            return Change(state: model)
        case let .setSuggestions(suggestions):
            var model = state
            model.suggestions = suggestions
            return Change(state: model)
        case let .suggestionsFailure(message):
            AppEnvironment.logger.debug(
                "Suggest failed: \(message)"
            )
            return Change(state: state)
        case let .commit(query, slug):
            return commit(state: state, query: query, slug: slug)
        case let .setDetail(results):
            var model = state
            model.query = results.query
            model.slug = results.slug
            model.backlinks = results.backlinks
            let entryURL = results.entry?.url
            model.entryURL = entryURL ?? AppEnvironment.database.findUniqueURL(
                name: results.slug
            )
            model.editorAttributedText = renderMarkup(
                markup: results.entry?.content ?? results.query
            )
            return Change(state: model)
        case let .detailFailure(message):
            AppEnvironment.logger.log(
                "Failed to get details for search: \(message)"
            )
            return Change(state: state)
        case let .setLinkSheetPresented(isPresented):
            var model = state
            model.focus = isPresented ? .linkSearch : nil
            model.isLinkSheetPresented = isPresented
            return Change(state: model)
        case let .setLinkSearch(text):
            return setLinkSearch(state: state, text: text)
        case let .commitLinkSearch(text):
            return commitLinkSearch(state: state, text: text)
        case let .setLinkSuggestions(suggestions):
            var model = state
            model.linkSuggestions = suggestions
            return Change(state: model)
        case let .linkSuggestionsFailure(message):
            AppEnvironment.logger.debug(
                "Link suggest failed: \(message)"
            )
            return Change(state: state)
        case .save:
            return save(state: state)
        case let .saveSuccess(url):
            AppEnvironment.logger.debug(
                "Saved entry \(url)"
            )
            return Change(state: state)
        case let .saveFailure(url, message):
            //  TODO: show user a "try again" banner
            AppEnvironment.logger.warning(
                "Save failed for entry (\(url)) with error: \(message)"
            )
            return Change(state: state)
        }
    }
}

//  MARK: Model
struct AppModel {
    /// Enum describing which view is currently focused.
    /// Focus is mutually exclusive, and SwiftUI's FocusedState requires
    /// modeling this state as an enum.
    /// See https://github.com/gordonbrander/subconscious/wiki/SwiftUI-FocusState
    /// 2021-12-23 Gordon Brander
    enum Focus: Hashable, Equatable {
        case search
        case linkSearch
        case editor
    }

    /// What is focused? (nil means nothing is focused)
    var focus: Focus? = nil

    /// Is database connected and migrated?
    var isDatabaseReady = false
    /// Is the detail view (edit and details for an entry) showing?
    var isDetailShowing = false

    //  Recent entries
    var recent: [EntryStub] = []

    //  Note deletion action sheet
    /// Delete confirmation action sheet
    var entryToDelete: String? = nil
    /// Delete confirmation action sheet
    var isConfirmDeleteShowing = false

    /// Live search bar text
    var searchText = ""
    var isSearchShowing = false

    /// Committed search bar query text
    var query = ""
    /// Slug committed during search
    var slug = ""

    /// Main search suggestions
    var suggestions: [Suggestion] = []

    // Editor
    var editorAttributedText = NSAttributedString("")
    /// Editor selection corresponds with `editorAttributedText`
    var editorSelection = NSMakeRange(0, 0)

    /// The URL for the currently active entry
    var entryURL: URL?
    /// Backlinks to the currently active entry
    var backlinks: [EntryStub] = []

    /// Link suggestions for modal and bar in edit mode
    var isLinkSheetPresented = false
    var linkSearchText = ""
    var linkSearchQuery = ""
    var linkSuggestions: [Suggestion] = []
}

//  MARK: View
struct AppView: View {
    @ObservedObject var store: Store<AppModel, AppAction>

    var body: some View {
        // Give each element in this ZStack an explicit z-index.
        // This keeps transitions working correctly.
        // SwiftUI will dynamically generate z-indexes when no explicit
        // z-index is given. This can cause transitions to layer incorrectly.
        // Adding an explicit z-index fixed problems with the
        // out-transition for the search view.
        // See https://stackoverflow.com/a/58512696
        // 2021-12-16 Gordon Brander
        ZStack(alignment: .bottomTrailing) {
            Color.background.edgesIgnoringSafeArea(.all)
            if store.state.isDatabaseReady {
                AppNavigationView(store: store).zIndex(1)
                if store.state.focus == nil {
                    Button(
                        action: {
                            withAnimation(.easeOut(duration: Duration.fast)) {
                                store.send(action: .showSearch)
                            }
                        },
                        label: {
                            Image(systemName: "plus")
                        }
                    )
                    .buttonStyle(FABButtonStyle())
                    .padding()
                    .transition(.opacity)
                    .zIndex(2)
                }
                if store.state.isSearchShowing {
                    SearchView(
                        placeholder: "Search or create...",
                        text: store.binding(
                            get: \.searchText,
                            tag: AppAction.setSearch
                        ),
                        focus: store.binding(
                            get: \.focus,
                            tag: AppAction.setFocus
                        ),
                        suggestions: store.binding(
                            get: \.suggestions,
                            tag: AppAction.setSuggestions
                        ),
                        onCommit: { query, slug in
                            if let slug = slug {
                                store.send(
                                    action: .commit(
                                        query: query,
                                        slug: slug
                                    )
                                )
                            } else {
                                store.send(
                                    action: .commitSearch(query: query)
                                )
                            }
                        },
                        onCancel: {
                            withAnimation(.easeOut(duration: Duration.fast)) {
                                store.send(
                                    action: .hideSearch
                                )
                            }
                        }
                    )
                    .transition(
                        .asymmetric(
                            insertion:
                                .move(edge: .bottom)
                                .combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                    .zIndex(3)
                }
            } else {
                ProgressScrim()
            }
        }
        .font(Font.appText)
        .onAppear {
            store.send(action: .appear)
        }
        .environment(\.openURL, OpenURLAction { url in
            store.send(action: .openURL(url))
            return .handled
        })
    }
}
