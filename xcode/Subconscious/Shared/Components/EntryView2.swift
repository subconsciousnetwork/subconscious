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
import OrderedCollections

/// A foldable note entry
struct EntryView2: View, Equatable {
    //  MARK: Action
    enum Action {
        case block(id: UUID, action: SubtextEditableBlockView.Action)
        case setFolded(Bool)
    }

    //  MARK: Model
    struct Model: Identifiable, Equatable {
        var id: URL {
            url
        }
        var url: URL
        var blocks: OrderedDictionary<UUID, SubtextEditableBlockView.Model>
        var isFolded = true
        var isTruncated: Bool {
            isFolded && blocks.values.count > 3
        }
        var visibleBlocks: [SubtextEditableBlockView.Model] {
            if isFolded && blocks.values.count > 3 {
                return Array(blocks.values.elements.prefix(3))
            } else {
                return blocks.values.elements
            }
        }

        init(
            url: URL,
            markup: String
        ) {
            self.url = url
            var blocks = OrderedDictionary<UUID, SubtextEditableBlockView.Model>()
            for line in markup.splitlines() {
                let block = SubtextEditableBlockView.Model(markup: String(line))
                blocks[block.id] = block
            }
            self.blocks = blocks
        }
    }

    //  MARK: Update
    static func update(
        state: inout Model,
        action: Action,
        environment: Logger
    ) -> AnyPublisher<Action, Never> {
        switch action {
        case .block(let id, let action):
            if state.blocks[id] != nil {
                return SubtextEditableBlockView.update(
                    state: &state.blocks[id]!,
                    action: action,
                    environment: environment
                ).map({ action in
                    tagEntry(
                        id: id,
                        action: action
                    )
                }).eraseToAnyPublisher()
            }
            // If we didn't find a block, do nothing.
            // This is a normal case. It can happen if
            // the block was deleted before an action sent to it was
            // delivered.
        case .setFolded(let isFolded):
            state.isFolded = isFolded
        }
        return Empty().eraseToAnyPublisher()
    }

    //  MARK: Tags
    static func tagEntry(
        id: UUID,
        action: SubtextEditableBlockView.Action
    ) -> Action {
        .block(id: id, action: action)
    }

    var store: ViewStore<Model, Action>
    var fixedWidth: CGFloat
    var padding: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.state.visibleBlocks) { block in
                SubtextEditableBlockView(
                    store: ViewStore(
                        state: block,
                        send: store.send,
                        tag: { action in
                            Self.tagEntry(
                                id: block.id,
                                action: action
                            )
                        }
                    ),
                    fixedWidth: fixedWidth - (padding * 2)
                ).equatable()
            }

            if store.state.isTruncated {
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
                }.padding(padding)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, padding)
        .background(Constants.Color.background)
    }
}

struct EntryView2_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            ScrollView {
                EntryView2(
                    store: ViewStore(
                        state: .init(
                            url: URL(fileURLWithPath: "example.subtext"),
                            markup:
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
                        ),
                        send: { action in }
                    ),
                    fixedWidth: geometry.size.width
                )
            }
        }
        .background(Constants.Color.secondaryBackground)
    }
}
