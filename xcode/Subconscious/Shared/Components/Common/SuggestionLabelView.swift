//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/28/22.
//

import SwiftUI

struct SuggestionLabelView: View, Equatable {
    var suggestion: Suggestion

    var body: some View {
        switch suggestion {
        case .entry(let entryLink):
            Label(
                title: {
                    Text(
                        entryLink.title.orUntitled("Untitled")
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
                        title: Text(
                            entryLink.title.orUntitled("Untitled")
                        ),
                        subtitle: Text(String(entryLink.slug))
                    )
                },
                icon: {
                    Image(systemName: "square.and.pencil")
                }
            )
        case .journal(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: Text("Daily journal"),
                        subtitle: Text(String(entryLink.slug))
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
                        title: Text("Scratch note"),
                        subtitle: Text(String(entryLink.slug))
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
                        subtitle: Text("Display a random idea")
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
