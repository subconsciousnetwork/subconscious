//
//  LoggerUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/20/22.
//

import os

extension Logger {
    static let main = Logger(subsystem: Config.rdns, category: "main")
    static let store = Logger(subsystem: Config.rdns, category: "store")
    static let editor = Logger(subsystem: Config.rdns, category: "editor")
}
