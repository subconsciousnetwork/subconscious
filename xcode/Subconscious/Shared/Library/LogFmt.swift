//
//  LogFmt.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/15/23.
//

import Foundation
import os

struct LogFmt {
    private static func escapeValuePart(_ value: String) -> String {
        value.replacingOccurrences(of: #"""#, with: #"\""#)
    }
    
    private static func formatParameter(
        key: String,
        value: String
    ) -> String {
        let value = Self.escapeValuePart(value)
        return #"\#(key)="\#(value)""#
    }

    /// Format a dictionary of parameters as a LogFmt string.
    ///
    /// Example of LogFmt style:
    ///
    ///     msg="Stopping all fetchers" tag=stopping_fetchers id=ConsumerFetcherManager-1382721708341 module=kafka.consumer.ConsumerFetcherManager
    ///
    /// See https://brandur.org/logfmt
    static func format(
        message: String,
        metadata: KeyValuePairs<String, String>
    ) -> String {
        var parameters = [formatParameter(key: "msg", value: message)]
        for (key, value) in metadata {
            let parameter = Self.formatParameter(key: key, value: value)
            parameters.append(parameter)
        }
        return parameters.joined(separator: " ")
    }
}


/// Extend logger to provide a LogFmt variant that allows you to log
/// `KeyValuePairs` as a LogFmt string.
extension Logger {
    /// Log `parameters` to JSON string, using given log `level`
    func log(
        level: OSLogType,
        message: String,
        metadata: KeyValuePairs<String, String>
    ) {
        let string = LogFmt.format(
            message: message,
            metadata: metadata
        )
        self.log(level: level, "\(string)")
    }
    
    /// Log `parameters` at default log level.
    func log(_ message: String, metadata: KeyValuePairs<String, String>) {
        log(level: .default, message: message, metadata: metadata)
    }
    
    /// Log `parameters` at info log level.
    func info(_ message: String, metadata: KeyValuePairs<String, String>) {
        log(level: .info, message: message, metadata: metadata)
    }
    
    /// Log `parameters` at debug log level.
    func debug(_ message: String, metadata: KeyValuePairs<String, String>) {
        log(level: .debug, message: message, metadata: metadata)
    }
    
    /// Log `parameters` at error log level.
    func error(_ message: String, metadata: KeyValuePairs<String, String>) {
        log(level: .error, message: message, metadata: metadata)
    }
    
    /// Log `parameters` at fault log level.
    func fault(_ message: String, metadata: KeyValuePairs<String, String>) {
        log(level: .fault, message: message, metadata: metadata)
    }
}
