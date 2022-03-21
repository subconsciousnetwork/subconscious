//
//  LoggerUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/20/22.
//

import os

extension Logger {
    // Main app logger
    static let main = Logger(subsystem: Config.rdns, category: "main")
    // Logger for store
    static let store = Logger(subsystem: Config.rdns, category: "store")
    // Logger for editor
    static let editor = Logger(subsystem: Config.rdns, category: "editor")
}
