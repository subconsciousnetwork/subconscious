//
//  AppEnvironment.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/16/21.
//

import Foundation
import SwiftUI
import os

/// A place for constants and services
enum AppEnvironment {}

//  MARK: Basics
extension AppEnvironment {
    static let rdns = "com.subconscious.Subconscious"
    static let untitled = "Untitled"

    static let documentURL = FileManager.default.urls(
        for: .documentDirectory,
           in: .userDomainMask
    ).first!

    static let applicationSupportURL = try! FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
}

//  MARK: Logger
extension AppEnvironment {
    static let logger = Logger(
        subsystem: rdns,
        category: "main"
    )
}

//  MARK: Migrations
extension AppEnvironment {
    static let migrations = SQLite3Migrations([
        SQLite3Migrations.Migration(
            date: "2021-11-04T12:00:00",
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
        )!
    ])!
}

//  MARK: Database service
extension AppEnvironment {
    static let database = DatabaseService(
        documentURL: FileManager.default.documentDirectoryUrl!,
        databaseURL: applicationSupportURL
            .appendingPathComponent("database.sqlite"),
        migrations: migrations
    )
}

enum AppTheme {}


//  MARK: Theme units
extension AppTheme {
    static let unit: CGFloat = 4
    static let unit2 = unit * 2
    static let unit4 = unit * 4
    static let cornerRadius: Double = 20
    static let padding = unit4
    static let tightPadding = unit * 3
    static let icon: CGFloat = unit * 6
}

//  MARK: Fonts
extension UIFont {
    static let appText = UIFont.systemFont(ofSize: 17)
    static let appTextBold = UIFont.boldSystemFont(ofSize: 17)
}

//  MARK: Color
/// String color names are references to ColorSet assets, and can be found in Assets.xassets
/// Each ColorSet contains a light and dark mode, and color is resolved at runtime.
extension Color {
    static let text = SwiftUI.Color("TextColor")
    static let secondaryText = SwiftUI.Color("SecondaryTextColor")
    static let placeholderText = SwiftUI.Color("PlaceholderTextColor")
    static let disabledText = placeholderText
    static let accent = SwiftUI.Color.accentColor
    static let icon = accent
    static let background = SwiftUI.Color("BackgroundColor")
    static let secondaryBackground = SwiftUI.Color("SecondaryBackgroundColor")
    static let buttonText = accent
    static let pressedText = placeholderText
    static let pressedBackground = secondaryBackground
}

//  MARK: Animation durations
typealias Duration = Double

extension Duration {
    static let fast: Double = 0.128
    static let normal: Double = 0.2
}
