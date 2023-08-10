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
    
    public static func formatParameter(
        key: String,
        value: String?
    ) -> String {
        let value = Self.escapeValuePart(value ?? "nil")
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
        metadata: KeyValuePairs<String, String?>
    ) -> String {
        var parameters: [String] = []
        for (key, value) in metadata {
            let parameter = Self.formatParameter(key: key, value: value)
            parameters.append(parameter)
        }
        return parameters.joined(separator: " ")
    }
}

typealias LoggingMetadata = KeyValuePairs<String, String?>

/// Extend logger to provide a LogFmt variant that allows you to log
/// `KeyValuePairs` as a LogFmt string.
extension Logger {
    /// Log `parameters` to JSON string, using given log `level`
    func log_lines(
        level: OSLogType,
        message: String,
        metadata: LoggingMetadata
    ) {
        for kv in metadata {
            self.log(
                level: level,
                """
                \(message, privacy: .public) \
                [\(kv.key): \(String(describing: kv.value), privacy: .private(mask: .hash))]
                """
            )
        }
    }
    
    /// Log `parameters` to JSON string, using given log `level`
    func log(
        level: OSLogType,
        message: String,
        metadata: LoggingMetadata
    ) {
        let string = LogFmt.format(
            message: message,
            metadata: metadata
        )
        
        let msg = LogFmt.formatParameter(key: "msg", value: message)
        
        self.log(
            level: level,
            "\(msg, privacy: .public) \(string, privacy: .private(mask: .hash))"
        )
    }
    
    /// Log `parameters` at default log level.
    func log(_ message: String, metadata: LoggingMetadata) {
        log(level: .default, message: message, metadata: metadata)
    }
    
    /// Log `parameters` at info log level.
    func info(_ message: String, metadata: LoggingMetadata) {
        log(level: .info, message: message, metadata: metadata)
    }
    
    /// Log `parameters` at debug log level.
    func debug(_ message: String, metadata: LoggingMetadata) {
        log(level: .debug, message: message, metadata: metadata)
    }
    
    /// Log `parameters` at error log level.
    func error(_ message: String, metadata: LoggingMetadata) {
        log(level: .error, message: message, metadata: metadata)
    }
    
    /// Log `parameters` at fault log level.
    func fault(_ message: String, metadata: LoggingMetadata) {
        log(level: .fault, message: message, metadata: metadata)
    }
}
