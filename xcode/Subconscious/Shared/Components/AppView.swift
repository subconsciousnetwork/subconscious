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

//  MARK: Model
struct AppModel: Updatable {
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

    // Is database connected and migrated?
    var isDatabaseReady = false
    // Is the detail view (edit and details for an entry) showing?
    var isDetailShowing = false

    // Recent entries
    var recent: [EntryStub] = []

    // Live search bar text
    var searchText = ""
    var isSearchShowing = false

    // Committed search bar query text
    var query = ""
    // Slug committed during search
    var slug = ""

    // Main search suggestions
    var suggestions: [Suggestion] = []

    // Editor
    var editorAttributedText = NSAttributedString("")
    // Editor selection corresponds with `editorAttributedText`
    var editorSelection = NSMakeRange(0, 0)

    // The URL for the currently active entry
    var entryURL: URL?
    // Backlinks to the currently active entry
    var backlinks: [EntryStub] = []

    // Link suggestions for modal and bar in edit mode
    var isLinkSheetPresented = false
    var linkSearchText = ""
    var linkSearchQuery = ""
    var linkSuggestions: [Suggestion] = []

    // Set all editor properties to initial values
    static func resetEditor(_ model: inout Self) {
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
            if self.focus == .editor {
                let fx = Just(
                    AppAction.setEditorSelection(range)
                ).eraseToAnyPublisher()
                return (self, fx)
            } else {
                if Slashlink.isSlashlinkURL(url) {
                    // If this is a Subtext URL, then commit a search for the
                    // corresponding query
                    let fx = Just(
                        AppAction.commitSearch(
                            query: Slashlink.urlToProse(url)
                        )
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
        case let .setFocus(focus):
            var model = self
            model.focus = focus
            return (model, Empty().eraseToAnyPublisher())
        case let .databaseReady(success):
            var model = self
            model.isDatabaseReady = true
            let sync = AppEnvironment.database.syncDatabase()
                .map({ changes in
                    AppAction.syncSuccess(changes)
                })
                .catch({ error in
                    Just(.syncFailure(error.localizedDescription))
                })
            let suggestions = Just(AppAction.setSearch(""))
            let linkSuggestions = Just(AppAction.setLinkSearchText(""))
            let recent = Just(AppAction.listRecent)
            let fx = Publishers.Merge4(
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

        case .listRecent:
            let fx = AppEnvironment.database.listRecentEntries()
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
            return (self, fx)
        case let .setRecent(entries):
            var model = self
            model.recent = entries
            return (model, Empty().eraseToAnyPublisher())
        case let .listRecentFailure(error):
            AppEnvironment.logger.warning(
                "Failed to list recent entries: \(error)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .setEditorAttributedText(attributedText):
            var model = self
            // Render attributes from markup if text has changed
            if !self.editorAttributedText.isEqual(to: attributedText) {
                // Rerender attributes from markup, then assign to
                // model.
                model.editorAttributedText = Self.renderMarkup(
                    markup: attributedText.string
                )
            }
            return (model, Empty().eraseToAnyPublisher())
        case let .setEditorSelection(range):
            var model = self
            model.editorSelection = range
            return (model, Empty().eraseToAnyPublisher())
        case let .setDetailShowing(isShowing):
            var model = self
            model.isDetailShowing = isShowing
            if isShowing == false {
                model.focus = nil
            }
            return (model, Empty().eraseToAnyPublisher())
        case let .setSearch(text):
            var model = self
            model.searchText = text
            let fx = AppEnvironment.database.searchSuggestions(
                query: text
            ).map({ suggestions in
                AppAction.setSuggestions(suggestions)
            }).catch({ error in
                Just(.suggestionsFailure(error.localizedDescription))
            }).eraseToAnyPublisher()
            return (model, fx)
        case .showSearch:
            var model = self
            model.isSearchShowing = true
            model.searchText = ""
            model.focus = .search
            return (model, Empty().eraseToAnyPublisher())
        case .hideSearch:
            var model = self
            model.isSearchShowing = false
            model.searchText = ""
            model.focus = nil
            return (model, Empty().eraseToAnyPublisher())
        case let .setSuggestions(suggestions):
            var model = self
            model.suggestions = suggestions
            return (model, Empty().eraseToAnyPublisher())
        case let .suggestionsFailure(message):
            AppEnvironment.logger.debug(
                "Suggest failed: \(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .commit(query, slug):
            var model = self
            Self.resetEditor(&model)
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
            let fx = Publishers.Merge(
                suggest,
                search
            ).eraseToAnyPublisher()

            return (model, fx)
        case let .setDetail(results):
            var model = self
            model.query = results.query
            model.slug = results.slug
            model.backlinks = results.backlinks
            let entryURL = results.entry?.url
            model.entryURL = entryURL ?? AppEnvironment.database.findUniqueURL(
                name: results.slug
            )
            model.editorAttributedText = Self.renderMarkup(
                markup: results.entry?.content ?? results.query
            )
            return (model, Empty().eraseToAnyPublisher())
        case let .detailFailure(message):
            AppEnvironment.logger.log(
                "Failed to get details for search: \(message)"
            )
            return (self, Empty().eraseToAnyPublisher())
        case let .setLinkSheetPresented(isPresented):
            var model = self
            model.focus = isPresented ? .linkSearch : nil
            model.isLinkSheetPresented = isPresented
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
            if let range = Range(
                model.editorSelection,
                in: editorAttributedText.string
            ) {
                // Replace selected range with committed link search text.
                let markup = editorAttributedText.string.replacingCharacters(
                    in: range,
                    with: text
                )
                // Re-render and assign
                model.editorAttributedText = Self.renderMarkup(markup: markup)
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
            model.focus = nil
            if let entryURL = model.entryURL {
                // Parse editorAttributedText to entry.
                // TODO refactor model to store entry instead of attributedText.
                let entry = SubtextFile(
                    url: entryURL,
                    content: model.editorAttributedText.string
                )
                let fx = AppEnvironment.database.writeEntry(
                    entry: entry
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
                .zIndex(2)
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
                VStack(alignment: .center) {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }
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
