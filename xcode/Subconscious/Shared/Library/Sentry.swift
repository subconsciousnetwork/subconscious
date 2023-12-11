//
//  Sentry.swift
//  Subconscious
//
//  Created by Ben Follington on 21/6/2023.
//

import Foundation
import os
import OSLog
import Sentry

// Create a generic protocol for an error-capturing service.
// We can use this instead of referencing the Sentry SDK directly.
protocol ErrorLoggingServiceProtocol {
    func capture(error: Error)
}

extension ErrorLoggingServiceProtocol {
    /// Run an async throwing closure, logging any errors as a side-effect
    /// before re-throwing.
    func capturing<T>(_ perform: () async throws -> T) async throws -> T {
        do {
            return try await perform()
        } catch {
            capture(error: error)
            throw error
        }
    }
}

struct SentryIntegration {}

extension SentryIntegration: ErrorLoggingServiceProtocol {
    func capture(error: Error) {
        SentrySDK.capture(error: error)
    }
}

extension SentryIntegration {
    public static let pipe = Pipe()
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "StdOut"
    )
    
    /// Redirect STDOUT to a logger to capture it in production
    public static func openConsolePipe () {
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            let str = String(data: data, encoding: .ascii) ?? "<Non-ascii data of size\(data.count)>\n"
            DispatchQueue.main.async {
                logger.log("\(str, privacy: .public)")
            }
        }
    }
    
    public static func start() {
        // If we're in test mode we skip sentry initialization altogether
        if ProcessInfo.processInfo.environment["TEST"] != nil {
            return
        }
      
        openConsolePipe()
       
        SentrySDK.start { options in
            // per https://docs.sentry.io/product/sentry-basics/dsn-explainer/#dsn-utilization this is fine to be public, unless it's abused (e.g. someone sending us /extra/ errors.
            options.dsn = "https://72ea1a54aeb04f60880d75fcffe705ed@o4505393671569408.ingest.sentry.io/4505393756438528"
            options.environment = Config.default.debug ? "development" : "production"
            options.beforeSend = { event in
                let ev = event
                if ev.breadcrumbs == nil {
                    ev.breadcrumbs = []
                }
                
                let crumbs = getCrumbs()
                ev.breadcrumbs?.append(contentsOf: crumbs)
                return ev
            }
        }
    }
    
    private static func getCrumbs() -> [Breadcrumb] {
        var crumbs: [Breadcrumb] = []
        do {
            let logStore = try OSLogStore(scope: .currentProcessIdentifier)
            let logs = try logStore.getEntries()
            
            for l in logs {
                guard let item = l as? OSLogEntryLog else {
                    continue
                }
                
                // There are many other system log categories to filter out
                guard item.category == "app" else {
                    continue
                }
                
                let crumb = Breadcrumb(
                    level: item.level.toSentry(),
                    category: item.category
                )
                crumb.message = item.composedMessage
                crumb.timestamp = item.date
                crumb.type = "log"
                crumbs.append(crumb)
            }
        } catch {
            return crumbs
        }
        
        return crumbs
    }
}

extension OSLogType {
    func toSentry() -> Sentry.SentryLevel {
        switch (self) {
        case .debug:
            return .debug
        case .info:
            return .info
        case .error:
            return .error
        case .fault:
            return .fatal
        default:
            return .debug
        }
    }
}

extension OSLogEntryLog.Level {
    func toSentry() -> Sentry.SentryLevel {
        switch (self) {
        case .debug:
            return .debug
        case .info:
            return .info
        case .error:
            return .error
        case .fault:
            return .fatal
        default:
            return .debug
        }
    }
}
