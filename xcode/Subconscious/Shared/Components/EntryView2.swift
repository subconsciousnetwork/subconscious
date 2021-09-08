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
        case insertBreak(id: UUID, at: NSRange)
        case deleteBreak(id: UUID, at: NSRange)
        case delete(id: UUID)
        case insert(after: UUID, block: SubtextEditableBlockView.Model)

        static func setMarkup(id: UUID, markup: String) -> Self {
            .block(id: id, action: .setMarkup(markup))
        }

        static func setFocus(id: UUID, isFocused: Bool) -> Self {
            .block(id: id, action: .setFocus(isFocused))
        }

        static func setSelection(id: UUID, range: NSRange) -> Self {
            .block(id: id, action: .setSelection(range))
        }
    }

    //  MARK: Tags
    static func tagEntry(
        id: UUID,
        action: SubtextEditableBlockView.Action
    ) -> Action {
        switch action {
        case .insertBreak(let range):
            return .insertBreak(id: id, at: range)
        case .deleteBreak(let range):
            return .deleteBreak(id: id, at: range)
        default:
            return .block(id: id, action: action)
        }
    }

    //  MARK: Model
    struct Model: Identifiable, Equatable {
        enum ModelError: Error {
            case idNotFound(id: UUID)
            case indexOutOfBounds
        }

        var id: URL {
            url
        }
        var url: URL
        var blocks: OrderedDictionary<UUID, SubtextEditableBlockView.Model>
        var isFolded = false
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
                    // Pass in a reference, not a copy!
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
            // If block does not exist, do nothing.
            // This is ok and can happen if block was deleted
            // after action was sent.
        case .delete(let id):
            // Remove value if key exists, or do nothing if it doesn't.
            state.blocks.removeValue(forKey: id)
        case .insert(let id, let block):
            if
                let upperIndex = state.blocks.index(forKey: id),
                let lowerIndex = state.blocks.index(upperIndex, offsetBy: 1)
            {
                let blocks = state.blocks.inserting(
                    key: block.id,
                    value: block,
                    at: lowerIndex
                )
                // Set new block `OrderedDictionary` as new state.
                state.blocks = blocks
            // If insertion block does not exist append to end.
            // This is an error case that should not happen, but we want to
            // handle it without data loss, in case block was somehow deleted
            // after action was sent.
            } else {
                state.blocks[block.id] = block
            }
        case .setFolded(let isFolded):
            state.isFolded = isFolded
        case .insertBreak(let id, let nsRange):
            if
                let markup = state.blocks[id]?.dom.markup,
                let sel = Range(nsRange, in: markup)
            {
                let upperMarkup = String(
                    markup[markup.startIndex..<sel.lowerBound]
                )
                let lowerMarkup = String(
                    markup[sel.upperBound..<markup.endIndex]
                )
                let lowerBlock = SubtextEditableBlockView.Model(
                    markup: lowerMarkup
                )
                return Publishers.Merge3(
                    Just(
                        Action.setMarkup(
                            id: id,
                            markup: upperMarkup
                        )
                    ),
                    Just(
                        Action.insert(
                            after: id,
                            block: lowerBlock
                        )
                    ),
                    Just(
                        Action.setFocus(
                            id: lowerBlock.id,
                            isFocused: true
                        )
                    )
                ).eraseToAnyPublisher()
            }
            // If block isn't found, do nothing.
        case .deleteBreak(let id, _):
            if
                let lower = state.blocks[id],
                // Only delete break if there is a previous block.
                // Deleting empty block with no previous (e.g. index 0)
                // is a no-op.
                let upperId = state.blocks.key(before: id),
                let upper = state.blocks[upperId]
            {
                let upperMarkup = upper.dom.markup + lower.dom.markup
                let selection = NSRange(
                    upper.dom.markup.endIndex..<upper.dom.markup.endIndex,
                    in: upper.dom.markup
                )
                return Publishers.Merge4(
                    Just(
                        Action.setMarkup(
                            id: upperId,
                            markup: upperMarkup
                        )
                    ),
                    Just(
                        Action.setFocus(
                            id: upperId,
                            isFocused: true
                        )
                    ),
                    Just(
                        Action.setSelection(
                            id: upperId,
                            range: selection
                        )
                    ),
                    Just(
                        Action.delete(
                            id: id
                        )
                    )
                ).eraseToAnyPublisher()
            }
        }
        return Empty().eraseToAnyPublisher()
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
