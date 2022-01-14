//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI

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
