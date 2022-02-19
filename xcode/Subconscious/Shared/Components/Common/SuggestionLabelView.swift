//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/28/22.
//

import SwiftUI

struct SuggestionLabelView: View {
    var suggestion: Suggestion
    var untitled = "Untitled"

    private func readTitle(_ text: String) -> String {
        text.isEmpty ? untitled : text
    }

    var body: some View {
        switch suggestion {
        case .entry(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: readTitle(entryLink.title),
                        subtitle: entryLink.slug.description
                    )
                },
                icon: {
                    Image(systemName: "doc")
                }
            )
        case .search(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: readTitle(entryLink.title),
                        subtitle: entryLink.slug.description
                    )
                },
                icon: {
                    Image(systemName: "doc.badge.plus")
                }
            )
        case .journal(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: "Daily journal",
                        subtitle: entryLink.slug.description
                    )
                },
                icon: {
                    Image(systemName: "calendar")
                }
            )
        case .scratch(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: "Scratch note",
                        subtitle: entryLink.slug.description
                    )
                },
                icon: {
                    Image(systemName: "square.and.pencil")
                }
            )
        case .random:
            Label(
                title: {
                    TitleGroupView(
                        title: "Random",
                        subtitle: "Display a random idea"
                    )
                },
                icon: {
                    Image(systemName: "dice")
                }
            )
        }
    }
}

struct SuggestionLabelView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionLabelView(
            suggestion: .search(
                EntryLink(
                    slug: Slug("floop")!,
                    title: "Floop the pig"
                )
            )
        )
    }
}
