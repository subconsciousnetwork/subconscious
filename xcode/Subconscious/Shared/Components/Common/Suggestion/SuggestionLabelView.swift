//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/28/22.
//

import SwiftUI

struct SuggestionCreateHeading: View {
    var label: String
    var fallback: String

    private var preview: String {
        fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if !preview.isEmpty {
            HStack {
                Text(label)
                Text(verbatim: #""\#(preview)""#)
                    .foregroundColor(.secondary)
            }
        } else {
            HStack {
                Text(label)
            }
        }
    }
}

struct SuggestionLabelView: View, Equatable {
    var suggestion: Suggestion

    var body: some View {
        switch suggestion {
        case let .memo(address, title):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(
                            verbatim: !title.isEmpty ?
                                title :
                                String(localized: "Empty note")
                        ),
                        subtitle: SlashlinkDisplayView(slashlink: address)
                            .theme(base: .secondary, slug: .secondary)
                    )
                },
                icon: {
                    Image(address)
                }
            )
        case let .createLocalMemo(_, fallback):
            Label(
                title: {
                    TitleGroupView(
                        title: SuggestionCreateHeading(
                            label: String(localized: "New draft"),
                            fallback: fallback
                        ),
                        subtitle: Text("Private draft")
                    )
                },
                icon: {
                    Image(systemName: "circle.dashed")
                }
            )
        case let .createPublicMemo(_, fallback):
            Label(
                title: {
                    TitleGroupView(
                        title: SuggestionCreateHeading(
                            label: String(localized: "New note"),
                            fallback: fallback
                        ),
                        subtitle: Text("Public note")
                    )
                },
                icon: {
                    Image(systemName: "network")
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
                suggestion: .createPublicMemo(
                    slug: Slug(
                        "a-muse-is-more-interesting-than-an-oracle"
                    )
                )
            )
            SuggestionLabelView(
                suggestion: .createLocalMemo(
                    slug: Slug(
                        "a-muse-is-more-interesting-than-an-oracle"
                    )
                )
            )
            SuggestionLabelView(
                suggestion: .createLocalMemo(
                    fallback: "RAND Corp"
                )
            )
            SuggestionLabelView(
                suggestion: .memo(
                    address: Slashlink.local(
                        Slug("the-lee-shore")!
                    ),
                    fallback: "The Lee Shore"
                )
            )
            SuggestionLabelView(
                suggestion: .memo(
                    address: Slashlink(
                        "/the-lee-shore"
                    )!,
                    fallback: "The Lee Shore"
                )
            )
            SuggestionLabelView(
                suggestion: .memo(
                    address: Slashlink(
                        "@bob/the-lee-shore"
                    )!,
                    fallback: "The Lee Shore"
                )
            )
            SuggestionLabelView(
                suggestion: .memo(
                    address: Slashlink(
                        "@carol.bob/the-lee-shore"
                    )!,
                    fallback: "The Lee Shore"
                )
            )
            SuggestionLabelView(
                suggestion: .memo(
                    address: Slashlink(
                        "did:key:abc123/the-lee-shore"
                    )!,
                    fallback: "The Lee Shore"
                )
            )
        }
    }
}
