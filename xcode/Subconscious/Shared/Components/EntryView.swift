//
//  Entry.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/6/21.
//

import SwiftUI
import Combine
import os
import Elmo

/// A foldable note entry
struct EntryView: View, Equatable {
    enum Action {
        case setFolded(_ isFolded: Bool)
        case requestEdit(url: URL)
        case activateWikilink(String)
    }

    struct Model: Identifiable, Equatable {
        var id: URL {
            fileEntry.url
        }
        var fileEntry: FileEntry
        var transcludes = SlugIndex<FileEntry>()
        var isFolded: Bool = true
    }

    static func update(
        state: inout Model,
        action: Action,
        environment: Logger
    ) -> AnyPublisher<Action, Never> {
        switch action {
        case .setFolded(let isFolded):
            state.isFolded = isFolded
        case .requestEdit:
            environment.debug(
                """
                EntryAction.requestEdit
                Action should be handled by parent view.
                """
            )
        case .activateWikilink:
            environment.debug(
                """
                EntryAction.activateWikilink
                Action should be handled by parent view.
                """
            )
        }
        return Empty().eraseToAnyPublisher()
    }

    let store: ViewStore<Model, Action>
    let showBlocksWhenFolded = 3

    var visibleDom: Subtext {
        store.state.isFolded
        ? store.state.fileEntry.dom.prefix(showBlocksWhenFolded)
        : store.state.fileEntry.dom
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(visibleDom.blocks) { block in
                BlockView(block: block).equatable()

                if let slug = block.extractWikilinks().first?.toSlug(),
                   let fileEntry = store.state.transcludes.get(slug) {
                    Button(
                        action: {
                            store.send(.activateWikilink(fileEntry.title))
                        },
                        label: {
                            TranscludeView(
                                dom: fileEntry.dom
                            )
                        }
                    )
                }
            }

            if (
                store.state.isFolded &&
                (
                    store.state.fileEntry.dom.blocks.count >
                    showBlocksWhenFolded
                )
            ) {
                HStack {
                    Button(action: {
                        store.send(.setFolded(false))
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Constants.Color.secondaryIcon)
                            .padding(8)
                    }
                    .background(Constants.Color.primaryButtonBackground)
                    .cornerRadius(8)

                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Constants.Color.background)
        .onTapGesture {
            store.send(
                .requestEdit(url: store.state.fileEntry.url)
            )
        }
    }
}

struct EntryView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            EntryView(
                store: ViewStore(
                    state: .init(
                        fileEntry: .init(
                            url: URL(fileURLWithPath: "example.subtext"),
                            content:
                                """
                                # Overview

                                Evolution is a behavior that emerges in any [[system]] with:

                                - Mutation
                                - Heredity
                                - Selection

                                Evolutionary systems often generate unexpected solutions. Nature selects for good enough.

                                > There is no such thing as advantageous in a general sense. There is only advantageous for the circumstances you’re living in. (Olivia Judson, Santa Fe Institute)

                                Evolving systems exist in [[punctuated equilibrium]].

                                & punctuated-equilibrium.st

                                # Questions

                                - What systems (beside biology) exhibit evolutionary behavior? Remember, evolution happens in any system with mutation, heredity, selection.
                                - What happens to an evolutionary system when you remove mutation? Heredity? Selection?
                                - Do you see a system with one of these properties? How can you introduce the other two?

                                # See also

                                & https://en.wikipedia.org/wiki/Evolutionary_systems
                                """
                        )
                    ),
                    send: { action in }
                )
            )
            Spacer()
        }
        .background(Constants.Color.secondaryBackground)
    }
}
