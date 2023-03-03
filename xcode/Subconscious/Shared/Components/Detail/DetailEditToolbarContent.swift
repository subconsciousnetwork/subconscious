//
//  DetailEditToolbarContent.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI

/// Toolbar for detail view
struct DetailEditToolbarContent: ToolbarContent {
    var address: MemoAddress? = nil
    var title: String? = nil
    var onDone: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            EmptyView()
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: onDone) {
                Text("Done").bold()
            }
        }
    }
}
