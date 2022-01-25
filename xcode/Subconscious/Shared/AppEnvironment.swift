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
    static let unit3 = unit * 3
    static let unit4 = unit * 4
    static let cornerRadius: Double = 8
    static let padding = unit * 4
    static let margin = unit * 4
    static let tightPadding = unit * 3
    static let icon: CGFloat = unit * 6
    static let textSize: CGFloat = 16
    // Unlike in CSS, line-spacing is not described as the total height of a
    // line. Instead, it is is measured as leading,
    // from bottom of one line to top of the next.
    // 4 + 4 = 8
    // 8 + 16 = 24
    // 8 * 1.5 = 24
    // 2021-12-10 Gordon Brander
    static let lineSpacing: CGFloat = 4
    static let lineHeight: CGFloat = 24
    static let fabSize: CGFloat = 56
}

//  MARK: UIFonts
extension UIFont {
    static let appText = UIFont(
        name: "IBMPlexSans",
        size: AppTheme.textSize
    )!

    static let appTextMedium = UIFont(
        name: "IBMPlexSans-Medium",
        size: AppTheme.textSize
    )!

    static let appTextMono = UIFont(
        name: "IBMPlexMono",
        size: AppTheme.textSize
    )!

    static let appTextMonoBold = UIFont(
        name: "IBMPlexMono-Bold",
        size: AppTheme.textSize
    )!

    static let appLargeTitle = UIFont(name: "IBMPlexSans-Light", size: 34)!

    static let appTitle = appTextMedium
    static let appButton = appTextMedium

    static let appCaption = UIFont(
        name: "IBMPlexSans",
        size: 12
    )!
}

//  MARK: Fonts
//  Note you can convert from UIFont to Font easily, but you can't yet convert
//  from Font to UIFont. So, we define our fonts as UIFonts and then provide
//  helpful proxies here.
//  2021-12-15 Gordon Brander
extension Font {
    static let appText = Font(UIFont.appText)
    static let appTextMono = Font(UIFont.appTextMono)
    static let appTextMonoBold = Font(UIFont.appTextMonoBold)
    static let appLargeTitle = Font(UIFont.appLargeTitle)
    static let appTitle = Font(UIFont.appTitle)
    static let appCaption = Font(UIFont.appCaption)
}

//  MARK: Color
//  String color names are references to ColorSet assets, and can be found
//  in Assets.xassets. Each ColorSet contains a light and dark mode, and color
//  is resolved at runtime.
//  2021-12-15 Gordon Brander
extension Color {
    static let text = SwiftUI.Color("TextColor")
    static let textPressed = text.opacity(0.5)
    static let textDisabled = placeholderText
    static let secondaryText = SwiftUI.Color("SecondaryTextColor")
    static let placeholderText = SwiftUI.Color("PlaceholderTextColor")
    static let icon = SwiftUI.Color.accentColor
    static let buttonText = SwiftUI.Color.accentColor
    static let background = SwiftUI.Color("BackgroundColor")
    static let backgroundPressed = secondaryBackground
    static let secondaryBackground = SwiftUI.Color("SecondaryBackgroundColor")
    static let secondaryBackgroundPressed = secondaryBackground.opacity(0.5)
    static let inputBackground = SwiftUI.Color("InputBackgroundColor")
    static let primaryButtonBackground = SwiftUI.Color(
        "PrimaryButtonBackgroundColor"
    )
    static let primaryButtonBackgroundPressed = primaryButtonBackground
        .opacity(0.5)
    static let primaryButtonBackgroundDisabled = primaryButtonBackground
        .opacity(0.3)
    static let primaryButtonText = SwiftUI.Color("PrimaryButtonTextColor")
    static let primaryButtonTextPressed = fabText.opacity(0.5)
    static let primaryButtonTextDisabled = fabText.opacity(0.3)
    static let fabBackground = primaryButtonBackground
    static let fabBackgroundPressed = primaryButtonBackgroundPressed
    static let fabText = primaryButtonText
    static let fabTextPressed = primaryButtonTextPressed
    static let fabTextDisabled = primaryButtonTextDisabled
    static let scrim = SwiftUI.Color("ScrimColor")
}

//  MARK: Animation durations
typealias Duration = Double

extension Duration {
    static let fast: Double = 0.18
    // iOS default
    static let normal: Double = 0.2
}
