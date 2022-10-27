//
//  Schema.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/27/22.
//

import Foundation

/// Describes a SQL script for boostrapping an empty database
struct Schema: Hashable, Identifiable, CustomStringConvertible {
    /// The user version for this database structure
    var version: Int
    var sql: String
    var id: Int { version }
    var description: String { sql }
    
    /// SQL script to run on migration. Includes pragma `user_version` line.
    var script: String {
        """
        PRAGMA user_version = \(version);
        \(sql)
        """
    }
}
