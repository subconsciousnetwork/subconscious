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
    
    /// Format a dictionary of parameters as a LogFmt string.
    ///
    /// Example of LogFmt style:
    ///
    ///     msg="Stopping all fetchers" tag=stopping_fetchers id=ConsumerFetcherManager-1382721708341 module=kafka.consumer.ConsumerFetcherManager
    ///
    /// See https://brandur.org/logfmt
    static func format(_ parameters: KeyValuePairs<String, String>) -> String {
        parameters
            .map({ pair in
                let value = Self.escapeValuePart(pair.value)
                return #"\#(pair.key)="\#(value)""#
            })
            .joined(separator: " ")
    }
}

/// Extend logger to provide a LogFmt variant that allows you to log
/// `KeyValuePairs` as a LogFmt string.
extension Logger {
    /// Log `parameters` to JSON string, using given log `level`
    func log(level: OSLogType, parameters: KeyValuePairs<String, String>) {
        let string = LogFmt.format(parameters)
        self.log(level: level, "\(string)")
    }
    
    /// Log `parameters` at default log level.
    func log(_ parameters: KeyValuePairs<String, String>) {
        log(level: .default, parameters: parameters)
    }
    
    /// Log `parameters` at info log level.
    func info(_ parameters: KeyValuePairs<String, String>) {
        log(level: .info, parameters: parameters)
    }
    
    /// Log `parameters` at debug log level.
    func debug(_ parameters: KeyValuePairs<String, String>) {
        log(level: .debug, parameters: parameters)
    }
    
    /// Log `parameters` at error log level.
    func error(_ parameters: KeyValuePairs<String, String>) {
        log(level: .error, parameters: parameters)
    }
    
    /// Log `parameters` at fault log level.
    func fault(_ parameters: KeyValuePairs<String, String>) {
        log(level: .fault, parameters: parameters)
    }
}
