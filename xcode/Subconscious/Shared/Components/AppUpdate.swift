//
//  AppUpdate.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/14/22.
//
import SwiftUI
import os
import Combine

struct AppUpdate {
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

    static func renderMarkup(
        markup: String
    ) -> NSAttributedString {
        Subtext(markup: markup)
            .renderMarkup(url: Slashlink.slashlinkToURLString)
    }

    /// Set all editor properties to initial values
    static func resetEditor(state: AppModel) -> AppModel {
        var model = state
        model.editorAttributedText = NSAttributedString("")
        model.editorSelection = NSMakeRange(0, 0)
        model.focus = nil
        return model
    }

    static func appear(state: AppModel) -> Change<AppModel, AppAction> {
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

    static func openEditorURL(
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

    static func databaseReady(
        state: AppModel,
        success: SQLite3Migrations.MigrationSuccess
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.isDatabaseReady = true
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .syncDatabase()
            .map({ changes in
                AppAction.syncSuccess(changes)
            })
            .catch({ error in
                Just(AppAction.syncFailure(error.localizedDescription))
            })
            .merge(
                with: Just(AppAction.setSearch("")),
                Just(AppAction.setLinkSearch("")),
                Just(AppAction.listRecent)
            )
            .eraseToAnyPublisher()
        if success.from != success.to {
            AppEnvironment.logger.log(
                "Migrated database: \(success.from)->\(success.to)"
            )
        }
        AppEnvironment.logger.log("File sync started")
        return Change(state: model, fx: fx)
    }

    static func rebuildDatabase(
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

    static func listRecent(
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

    static func deleteEntry(
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

    static func deleteEntrySuccess(
        state: AppModel,
        slug: String
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.log("Deleted entry: \(slug)")
        //  Refresh lists in search fields after delete.
        //  This ensures they don't show the deleted entry.
        let fx: AnyPublisher<AppAction, Never> = Just(AppAction.setSearch(""))
            .merge(with: Just(AppAction.setLinkSearch("")))
            .eraseToAnyPublisher()
        return Change(
            state: state,
            fx: fx
        )
    }

    static func setSearch(
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

    static func commit(
        state: AppModel,
        query: String,
        slug: String
    ) -> Change<AppModel, AppAction> {
        var model = resetEditor(state: state)
        model.entryURL = nil
        model.searchText = ""
        model.isSearchShowing = false
        model.isDetailShowing = true

        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .search(
                query: query,
                slug: slug
            )
            .map({ results in
                AppAction.setDetail(results)
            })
            .catch({ error in
                Just(AppAction.detailFailure(error.localizedDescription))
            })
            .merge(with: Just(AppAction.setSearch("")))
            .eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }

    static func setLinkSearch(
        state: AppModel,
        text: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.linkSearchText = text

        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .searchSuggestions(query: text)
            .map({ suggestions in
                AppAction.setLinkSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    AppAction.linkSuggestionsFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }

    static func commitLinkSearch(state: AppModel, text: String) -> Change<AppModel, AppAction> {
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

    static func save(
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
}
