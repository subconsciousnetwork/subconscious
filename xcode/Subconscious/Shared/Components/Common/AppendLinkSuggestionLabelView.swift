//
//  AppendLinkSuggestionLabelView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/1/2024.
//

import SwiftUI

struct AppendLinkSuggestionLabelView: View, Equatable {
    var suggestion: AppendLinkSuggestion

    var body: some View {
        switch suggestion {
        case let .append(_, target):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(verbatim: target.slug.description),
                        subtitle: Text("Append link")
                    )
                },
                icon: {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .frame(width: AppTheme.icon, height: AppTheme.icon)
                }
            )
        }
    }
}

struct AppendLinkSuggestionLabelView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AppendLinkSuggestionLabelView(
                suggestion: .append(
                    address: Slashlink("@here/loomings")!,
                    target: Slashlink("@here/the-lee-shore")!
                )
            )
        }
    }
}
