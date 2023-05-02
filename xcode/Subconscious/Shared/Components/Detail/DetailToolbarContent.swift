//
//  DetailToolbarContent.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/15/22.
//

import SwiftUI

/// Toolbar for detail view
struct DetailToolbarContent: ToolbarContent {
    var address: Slashlink?
    var defaultAudience: Audience
    var onTapOmnibox: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button(action: onTapOmnibox) {
                OmniboxView(
                    address: address,
                    defaultAudience: defaultAudience
                )
            }
        }
    }
}

struct DetailToolbarContent_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack {
                Text("Hello world")
            }
            .toolbar(content: {
                DetailToolbarContent(
                    defaultAudience: .local,
                    onTapOmnibox: {}
                )
            })
        }
    }
}
