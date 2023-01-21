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

struct DebugBodyRecalculationView<Inner: View>: View {
    var view: Inner
    var tag: String

    var body: some View {
        Logger.view.debug("Recalculated: \(tag)")
        return view
    }
}

extension View {
    func debugBodyRecalculations(_ tag: String) -> some View {
        DebugBodyRecalculationView(view: self, tag: tag)
    }
}
