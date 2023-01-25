//
//  LoggerUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/20/22.
//

import os

extension Logger {
    // Main app logger
    static let main = Logger(
        subsystem: Config.default.rdns,
        category: "main"
    )
    // Logger for editor
    static let editor = Logger(
        subsystem: Config.default.rdns,
        category: "editor"
    )
}
