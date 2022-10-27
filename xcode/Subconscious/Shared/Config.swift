//
//  Config.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/19/22.
//

import Foundation

/// Feature flags and settings
struct Config: Equatable {
    let rdns = "com.subconscious.Subconscious"
    var debug = false

    var appTabs = true

    var notesDirectory = "notes"

    /// Standard interval at which to run long-polling services
    var pollingInterval: Double = 15

    /// Subsurface "orb" shader on main FAB
    var orbShaderEnabled = true

    /// Toggle scratch note suggestion feature
    var scratchSuggestionEnabled = true
    var scratchDefaultTitle = "Untitled"

    /// Toggle random suggestion feature
    var randomSuggestionEnabled = true

    /// Default links feature enabled?
    var linksEnabled = true
    /// Where to look for user-defined links
    var linksTemplate: Slug = Slug("_special/links")!
    /// Template for default links
    var linksFallback: [Slug] = [
        Slug("pattern")!,
        Slug("project")!,
        Slug("question")!,
        Slug("quote")!,
        Slug("book")!,
        Slug("reference")!,
        Slug("decision")!,
        Slug("person")!
    ]

    /// Toggle on/off simple Tracery-based Geists
    var traceryZettelkasten = "zettelkasten"
    var traceryCombo = "combo"
    var traceryProject = "project"
}

extension Config {
    static let `default` = Config()
}

//  MARK: Database Schema
extension Config {
    static let schema = Schema(
        version: 1,
        sql: """
        CREATE TABLE search_history (
            id TEXT PRIMARY KEY,
            query TEXT NOT NULL,
            created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE entry (
          slug TEXT PRIMARY KEY,
          title TEXT NOT NULL DEFAULT '',
          body TEXT NOT NULL,
          modified TEXT NOT NULL,
          size INTEGER NOT NULL
        );

        CREATE VIRTUAL TABLE entry_search USING fts5(
          slug,
          title,
          body,
          modified UNINDEXED,
          size UNINDEXED,
          content="entry",
          tokenize="porter"
        );

        /*
        Create triggers to keep fts5 virtual table in sync with content table.

        Note: SQLite documentation notes that you want to modify the fts table *before*
        the external content table, hence the BEFORE commands.

        These triggers are adapted from examples in the docs:
        https://www.sqlite.org/fts3.html#_external_content_fts4_tables_
        */
        CREATE TRIGGER entry_search_before_update BEFORE UPDATE ON entry BEGIN
          DELETE FROM entry_search WHERE rowid=old.rowid;
        END;

        CREATE TRIGGER entry_search_before_delete BEFORE DELETE ON entry BEGIN
          DELETE FROM entry_search WHERE rowid=old.rowid;
        END;

        CREATE TRIGGER entry_search_after_update AFTER UPDATE ON entry BEGIN
          INSERT INTO entry_search
            (
              rowid,
              slug,
              title,
              body,
              modified,
              size
            )
          VALUES
            (
              new.rowid,
              new.slug,
              new.title,
              new.body,
              new.modified,
              new.size
            );
        END;

        CREATE TRIGGER entry_search_after_insert AFTER INSERT ON entry BEGIN
          INSERT INTO entry_search
            (
              rowid,
              slug,
              title,
              body,
              modified,
              size
            )
          VALUES
            (
              new.rowid,
              new.slug,
              new.title,
              new.body,
              new.modified,
              new.size
            );
        END;
        """
    )
}
