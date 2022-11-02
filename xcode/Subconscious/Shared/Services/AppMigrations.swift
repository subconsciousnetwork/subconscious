//
//  AppMigrations.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/1/22.
//

import Foundation

/// Environment passed to app migrations
struct AppMigrationEnvironment {
    var memos: MemoStore
    var files: FileStore
}

extension AppMigrationEnvironment {
    static let migrations = Migrations<AppMigrationEnvironment>([
        Migration(
            parent: 0,
            version: Int.from(iso8601String: "2021-11-04T12:00:00")!,
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
        ),
        Migration(
            parent: Int.from(iso8601String: "2021-11-04T12:00:00")!,
            version: Int.from(iso8601String: "2022-11-01T18:46:00")!,
            sql: """
            /* Remove old tables */
            DROP TABLE entry;
            DROP TABLE entry_search;
            DROP TRIGGER entry_search_before_update;
            DROP TRIGGER entry_search_before_delete;
            DROP TRIGGER entry_search_after_update;
            DROP TRIGGER entry_search_after_insert;
            
            /* Create new memo table */
            CREATE TABLE memo (
                slug TEXT PRIMARY KEY,
                headers TEXT NOT NULL DEFAULT '[]',
                content_type TEXT NOT NULL,
                created TEXT NOT NULL,
                modified TEXT NOT NULL,
                title TEXT NOT NULL DEFAULT '',
                body TEXT NOT NULL,
                /* Plain text serialization of body for search purposes */
                description TEXT NOT NULL,
                /* Short description of body */
                excerpt TEXT NOT NULL DEFAULT '',
                /* List of all slugs in body */
                links TEXT NOT NULL DEFAULT '[]',
                /* Size of body (used in combination with modified for sync) */
                size INTEGER NOT NULL
            );
            
            CREATE VIRTUAL TABLE memo_search USING fts5(
                slug,
                headers UNINDEXED,
                content_type UNINDEXED,
                created UNINDEXED,
                modified UNINDEXED,
                title,
                body UNINDEXED,
                description,
                excerpt UNINDEXED,
                links UNINDEXED,
                size UNINDEXED,
                content="memo",
                tokenize="porter"
            );
            
            /*
            Create triggers to keep fts5 virtual table in sync with content table.

            Note: SQLite documentation notes that you want to modify the fts table *before*
            the external content table, hence the BEFORE commands.

            These triggers are adapted from examples in the docs:
            https://www.sqlite.org/fts3.html#_external_content_fts4_tables_
            */
            CREATE TRIGGER memo_search_before_update BEFORE UPDATE ON memo BEGIN
                DELETE FROM memo_search WHERE rowid=old.rowid;
            END;
            
            CREATE TRIGGER memo_search_before_delete BEFORE DELETE ON memo BEGIN
                DELETE FROM memo_search WHERE rowid=old.rowid;
            END;
            
            CREATE TRIGGER memo_search_after_update AFTER UPDATE ON memo BEGIN
                INSERT INTO memo_search (
                    rowid,
                    slug,
                    headers,
                    content_type,
                    created,
                    modified,
                    title,
                    body,
                    description,
                    excerpt,
                    links,
                    size
                )
                VALUES (
                    new.rowid,
                    new.slug,
                    new.headers,
                    new.content_type,
                    new.created,
                    new.modified,
                    new.title,
                    new.body,
                    new.description,
                    new.excerpt,
                    new.links,
                    new.size
                );
            END;

            CREATE TRIGGER memo_search_after_insert AFTER INSERT ON memo BEGIN
                INSERT INTO memo_search (
                    rowid,
                    slug,
                    headers,
                    content_type,
                    created,
                    modified,
                    title,
                    body,
                    description,
                    excerpt,
                    links,
                    size
                )
                VALUES (
                    new.rowid,
                    new.slug,
                    new.headers,
                    new.content_type,
                    new.created,
                    new.modified,
                    new.title,
                    new.body,
                    new.description,
                    new.excerpt,
                    new.links,
                    new.size
                );
            END;
            """,
            perform: { database, environment in
                
            }
        )
    ])
}
