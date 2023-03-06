//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/28/22.
//

import SwiftUI

struct SuggestionLabelView: View, Equatable {
    var suggestion: Suggestion
    var empty = String(localized: "Empty note")

    var body: some View {
        switch suggestion {
        case let .memo(address, title):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(
                            verbatim: !title.isEmpty ? title : empty
                        ),
                        subtitle: Text(
                            verbatim: address.toSlashlink().description
                        )
                    )
                },
                icon: {
                    Image(systemName: "doc")
                }
            )
        case let .create(_, fallback):
            Label(
                title: {
                    HStack {
                        Text("Create Note")
                        if !fallback.isEmpty {
                            Text(verbatim: #""\#(fallback)""#)
                                .foregroundColor(.secondary)
                        }
                    }
                    .lineLimit(1)
                },
                icon: {
                    Image(systemName: "square.and.pencil")
                }
            )
        case .random:
            Label(
                title: {
                    Text("Random")
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
        VStack {
            SuggestionLabelView(
                suggestion: .create(
                    address: MemoAddress.public(
                        Slashlink(
                            "@here/a-muse-is-more-interesting-than-an-oracle"
                        )!
                    )
                )
            )
            SuggestionLabelView(
                suggestion: .create(
                    fallback: "RAND Corp"
                )
            )
            SuggestionLabelView(
                suggestion: .memo(
                    address: MemoAddress.public(
                        Slashlink(
                            "@here/the-lee-shore"
                        )!
                    ),
                    fallback: "The Lee Shore"
                )
            )
        }
    }
}
