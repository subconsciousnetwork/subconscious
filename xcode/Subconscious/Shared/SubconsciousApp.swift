//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import Sentry
import OSLog

@main
struct SubconsciousApp: App {
    init() {
        SentrySDK.start { options in
            // per https://docs.sentry.io/product/sentry-basics/dsn-explainer/#dsn-utilization this is fine to be public, unless it's abused (e.g. someone sending us /extra/ errors.
            options.dsn = "https://72ea1a54aeb04f60880d75fcffe705ed@o4505393671569408.ingest.sentry.io/4505393756438528"
            options.beforeSend = { event in
                var ev = event
                var crumbs: [Breadcrumb] = []
                do {
                    let logStore = try OSLogStore(scope: .currentProcessIdentifier)
                    let logs = try logStore.getEntries()
                    
                    for l in logs {
                        guard let item = l as? OSLogEntryLog else {
                            continue
                        }
                        
                        guard item.category == "app" else {
                            continue
                        }
                        
                        let crumb = Breadcrumb(level: item.level.toSentry(), category: item.category)
                        crumb.message = item.composedMessage
                        crumbs.append(crumb)
                    }
                } catch {
                    
                }
                ev.breadcrumbs = crumbs
                
                return ev
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }

}
