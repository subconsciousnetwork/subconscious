//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/28/22.
//

import SwiftUI

struct SuggestionLabelView: View, Equatable {
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
                        title: Text(readTitle(entryLink.title)),
                        subtitle: Text(String(entryLink.address.slug))
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
                        title: Text(readTitle(entryLink.title)),
                        subtitle: Text(String(entryLink.address.slug))
                    )
                },
                icon: {
                    Image(systemName: "square.and.pencil")
                }
            )
        case .scratch(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: Text("Create note"),
                        subtitle: Text(String(entryLink.address.slug))
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
                        title: Text("Random"),
                        subtitle: Text("Display a random note")
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
                    address: MemoAddress.public(
                        Slashlink(
                            "@here/a-muse-is-more-interesting-than-an-oracle"
                        )!
                    ),
                    title: "A muse is more interesting than an oracle"
                )
            )
        )
    }
}
