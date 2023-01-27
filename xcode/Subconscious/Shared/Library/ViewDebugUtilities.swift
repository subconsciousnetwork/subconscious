//
//  ViewDebugUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//

import Foundation
import SwiftUI
import os

extension Logger {
    static let view = Logger(
        subsystem: Config.default.rdns,
        category: "view"
    )
}

struct DebugBodyRecalculationsView<Inner: View>: View {
    var view: Inner
    var tag: String
    var debug = true

    var body: some View {
        if debug {
            Logger.view.debug("\(tag) view recalculated")
        }
        return view
    }
}

extension View {
    func debugBodyRecalculations(
        _ tag: String,
        debug: Bool = true
    ) -> some View {
        return DebugBodyRecalculationsView(
            view: self,
            tag: tag,
            debug: debug
        )
    }
}
