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

struct SentryIntegration {}

extension SentryIntegration {
    public static func start() {
        SentrySDK.start { options in
            // per https://docs.sentry.io/product/sentry-basics/dsn-explainer/#dsn-utilization this is fine to be public, unless it's abused (e.g. someone sending us /extra/ errors.
            options.dsn = "https://72ea1a54aeb04f60880d75fcffe705ed@o4505393671569408.ingest.sentry.io/4505393756438528"
            options.beforeSend = { event in
                var ev = event
                ev.breadcrumbs = getCrumbs()
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
