//
//  SQLite3ConnectionManager.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/10/21.
//

import Foundation

final class SQLite3ConnectionManager {
    let url: URL
    let mode: SQLite3Connection.OpenMode
    private var database: SQLite3Connection?

    init(url: URL, mode: SQLite3Connection.OpenMode) {
        self.url = url
        self.mode = mode
    }

    /// Opens the connection and returns it.
    /// Harmless no-op if the connection is already open.
    func connection() throws -> SQLite3Connection {
        if let database = self.database {
            return database
        } else {
            let database = try SQLite3Connection(path: url.path, mode: mode)
            self.database = database
            return database
        }
    }

    /// Closes the database connection
    func close() {
        self.database = nil
    }
}
