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
                        subtitle: Text(String(entryLink.slug))
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
                        title: Text("Create note"),
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
                    slug: Slug("floop")!,
                    title: "Floop the pig"
                )
            )
        )
    }
}
