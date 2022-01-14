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
}
