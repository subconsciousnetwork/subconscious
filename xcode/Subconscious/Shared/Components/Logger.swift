//
//  Logger.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation
import Combine
import os


//  MARK: Action
/// Logging actions you can use in other modules
enum LoggerAction {
    case trace(_ message: String)
    case debug(_ message: String)
    case info(_ message: String)
    case notice(_ message: String)
    case warning(_ message: String)
    case error(_ message: String)
    case critical(_ message: String)
}

//  MARK: Update
extension LoggerAction {
    /// Logger effects you can use in other update functions
    static func log(action: LoggerAction, environment: Logger) {
        switch action {
        case .trace(let message):
            environment.trace("\(message)")
        case .debug(let message):
            environment.debug("\(message)")
        case .info(let message):
            environment.info("\(message)")
        case .notice(let message):
            environment.notice("\(message)")
        case .warning(let message):
            environment.warning("\(message)")
        case .error(let message):
            environment.error("\(message)")
        case .critical(let message):
            environment.critical("\(message)")
        }
    }
}
