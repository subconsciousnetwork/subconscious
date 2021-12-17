//
//  LinkSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

// A second label view that does not include the action label
struct LinkSuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case let .entry(stub):
            Label(
                title: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Slashlink.removeLeadingSlash(stub.slug))
                            .foregroundColor(Color.text)
                            .frame(height: AppTheme.icon)
                        Text(#"Link to "\#(stub.title)""#)
                            .foregroundColor(Color.secondaryText)
                            .frame(height: AppTheme.icon)
                    }
                },
                icon: {
                    Image(systemName: "link")
                }
            ).labelStyle(SuggestionLabelStyle())
        case let .search(stub):
            Label(
                title: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Slashlink.removeLeadingSlash(stub.slug))
                            .foregroundColor(Color.text)
                            .frame(height: AppTheme.icon)
                        Text("Link to new idea")
                            .foregroundColor(Color.secondaryText)
                            .frame(height: AppTheme.icon)
                    }
                },
                icon: {
                    Image(systemName: "link.badge.plus")
                }
            ).labelStyle(SuggestionLabelStyle())
        }
    }
}
