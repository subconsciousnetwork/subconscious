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
    // Logger for actions
    static let action = Logger(subsystem: Config.rdns, category: "action")
    // Logger for states
    static let state = Logger(subsystem: Config.rdns, category: "state")
    // Logger for editor
    static let editor = Logger(subsystem: Config.rdns, category: "editor")
}
