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
        case createBelow(id: UUID, markup: String)
        case createAbove(id: UUID, markup: String)
        case delete(id: UUID)
        case deleteEmpty(id: UUID)
        case mergeUp(id: UUID)
        case split(id: UUID, at: NSRange)

        static func setMarkup(id: UUID, markup: String) -> Self {
            .block(id: id, action: .setMarkup(markup))
        }

        static func setFocus(id: UUID, isFocused: Bool) -> Self {
            .block(id: id, action: .setFocus(isFocused))
        }

        static func appendMarkup(id: UUID, markup: String) -> Self {
            .block(id: id, action: .appendMarkup(markup))
        }
    }

    //  MARK: Tags
    static func tagEntry(
        id: UUID,
        action: SubtextEditableBlockView.Action
    ) -> Action {
        switch action {
        case .createBelow:
            return .createBelow(id: id, markup: "")
        case .createAbove:
            return .createAbove(id: id, markup: "")
        case .deleteEmpty:
            return .deleteEmpty(id: id)
        case .mergeUp:
            return .mergeUp(id: id)
        case .split(let range):
            return .split(id: id, at: range)
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

        mutating func append(
            after id: UUID,
            block: SubtextEditableBlockView.Model
        ) throws {
            let focusedIndex = try blocks.index(forKey: id)
                .unwrap(or: ModelError.idNotFound(id: id))
            // Insert new block after index
            let nextIndex = try blocks.index(focusedIndex, offsetBy: 1)
                .unwrap(or: ModelError.indexOutOfBounds)
            let blocks = blocks.inserting(
                key: block.id,
                value: block,
                at: nextIndex
            )
            // Set new block `OrderedDictionary` as new state.
            self.blocks = blocks
        }

        mutating func prepend(
            before id: UUID,
            block: SubtextEditableBlockView.Model
        ) throws {
            let index = try blocks.index(forKey: id)
                .unwrap(or: ModelError.idNotFound(id: id))
            // `inserting` inserts *before* given index, prepending.
            let blocks = blocks.inserting(
                key: block.id,
                value: block,
                at: index
            )
            // Set new block `OrderedDictionary` as new state.
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
            let action = String(reflecting: action)
            environment.debug(
                """
                Could not route action. Block does not exist.\t\(id)\t\(action)
                """
            )
        case .createBelow(let id, let markup):
            do {
                let block = SubtextEditableBlockView.Model(markup: markup)
                try state.append(after: id, block: block)
                return Just(
                    Action.setFocus(
                        id: block.id,
                        isFocused: true
                    )
                ).eraseToAnyPublisher()
            } catch Model.ModelError.idNotFound(let id) {
                environment.log(
                    """
                    Could not createBelow. Block does not exist.\t\(id)
                    """
                )
            } catch {
                environment.warning(
                    """
                    Unexpected error: \(error.localizedDescription)
                    """
                )
            }
        case .createAbove(let id, let markup):
            do {
                let block = SubtextEditableBlockView.Model(markup: markup)
                try state.prepend(before: id, block: block)
            } catch Model.ModelError.idNotFound(let id) {
                environment.log(
                    """
                    Could not createAbove. Block does not exist.\t\(id)
                    """
                )
            } catch {
                environment.warning(
                    """
                    Unexpected error: \(error.localizedDescription)
                    """
                )
            }
        case .delete(let id):
            state.blocks.removeValue(forKey: id)
        case .deleteEmpty(let id):
            if let index = state.blocks.index(forKey: id) {
                // Only delete empty if there is a previous block.
                // Deleting empty block with no previous (e.g. index 0)
                // is a no-op.
                if let prevIndex = state.blocks.index(index, offsetBy: -1) {
                    let prev = state.blocks.values[prevIndex]
                    state.blocks.removeValue(forKey: id)
                    return Just(
                        Action.setFocus(
                            id: prev.id,
                            isFocused: true
                        )
                    ).eraseToAnyPublisher()
                }
            } else {
                environment.log(
                    """
                    Could not delete empty block. Block does not exist.\t\(id)
                    """
                )
            }
        case .mergeUp(let id):
            if let focusedIndex = state.blocks.index(forKey: id),
               let block = state.blocks[id]
            {
                // Merge up for index 0 is a no-op
                if focusedIndex > 0 {
                    if let prevIndex = state.blocks.index(
                        focusedIndex,
                        offsetBy: -1
                    ) {
                        let prevId = state.blocks.keys[prevIndex]
                        return Publishers.Merge3(
                            Just(
                                Action.delete(id: id)
                            ),
                            Just(
                                Action.appendMarkup(
                                    id: prevId,
                                    markup: block.dom.markup
                                )
                            ),
                            Just(
                                Action.setFocus(
                                    id: prevId,
                                    isFocused: true
                                )
                            )
                        ).eraseToAnyPublisher()
                    }
                }
            } else {
                environment.log(
                    """
                    Could not merge up block. Block does not exist.\t\(id)
                    """
                )
            }
        case .split(let id, let nsRange):
            if
                let block = state.blocks[id],
                let range = Range(nsRange, in: block.dom.markup)
            {
                let markup = block.dom.markup
                let beforeText = markup[
                    markup.startIndex..<range.lowerBound
                ]
                let afterText = markup[
                    range.upperBound..<markup.endIndex
                ]
                return Publishers.Merge(
                    Just(
                        Action.createAbove(
                            id: id,
                            markup: String(beforeText)
                        )
                    ),
                    Just(
                        Action.setMarkup(
                            id: id,
                            markup: String(afterText)
                        )
                    )
                ).eraseToAnyPublisher()
            } else {
                environment.log(
                    """
                    Could not split block. Block does not exist.\t\(id)
                    """
                )
            }
        case .setFolded(let isFolded):
            state.isFolded = isFolded
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
                )
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
