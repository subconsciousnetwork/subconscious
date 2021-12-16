//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/28/21.
//

import SwiftUI

struct SuggestionTitleGroup: View {
    var title: String
    var subtitle: String
    var lineHeight: CGFloat = AppTheme.icon

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .foregroundColor(Color.text)
                .frame(height: AppTheme.icon)
            Text(subtitle)
                .foregroundColor(Color.secondaryText)
                .frame(height: AppTheme.icon)
        }
    }
}

struct SuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case let .entry(stub):
            Label(
                title: {
                    SuggestionTitleGroup(
                        title: stub.title,
                        subtitle: Slashlink.removeLeadingSlash(stub.slug)
                    )
                },
                icon: {
                    Image(systemName: "doc")
                }
            ).labelStyle(SuggestionLabelStyle())
        case let .search(stub):
            Label(
                title: {
                    SuggestionTitleGroup(
                        title: stub.title,
                        subtitle: "Create idea"
                    )
                },
                icon: {
                    Image(systemName: "doc.badge.plus")
                }
            ).labelStyle(SuggestionLabelStyle())
        }
    }
}

// A second label view that does not include the action label
struct SuggestionLabelView2: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case let .entry(stub):
            Label(
                title: {
                    SuggestionTitleGroup(
                        title: stub.title,
                        subtitle: Slashlink.removeLeadingSlash(stub.slug)
                    )
                },
                icon: {
                    Image(systemName: "doc")
                }
            ).labelStyle(SuggestionLabelStyle())
        case let .search(stub):
            Label(
                title: {
                    SuggestionTitleGroup(
                        title: stub.title,
                        subtitle: Slashlink.removeLeadingSlash(stub.slug)
                    )
                },
                icon: {
                    Image(systemName: "magnifyingglass")
                }
            ).labelStyle(SuggestionLabelStyle())
        }
    }
}

struct SuggestionLabel_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionLabelView(
            suggestion: .search(
                Stub(title: "Floop the pig")
            )
        )
    }
}
