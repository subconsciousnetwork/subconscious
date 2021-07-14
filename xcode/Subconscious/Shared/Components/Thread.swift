//
//  ThreadView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/6/21.
//

import SwiftUI
import Combine
import os

enum ThreadAction {
    case setFolded(_ isFolded: Bool)
    case requestEdit(url: URL)
}

struct ThreadModel: Identifiable, Equatable {
    var id: URL {
        url
    }
    var url: URL
    var dom: Subtext
    var isFolded: Bool = true
}

func updateThread(
    state: inout ThreadModel,
    action: ThreadAction,
    environment: Logger
) -> AnyPublisher<ThreadAction, Never> {
    switch action {
    case .setFolded(let isFolded):
        state.isFolded = isFolded
    case .requestEdit:
        environment.warning(
            """
            ThreadAction.requestEdit
            This action should have been handled by the parent view.
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

/// A foldable thread
struct ThreadView: View, Equatable {
    let store: ViewStore<ThreadModel, ThreadAction>
    let maxBlocksWhenFolded = 3

    var visibleBlocks: [Subtext.Block] {
        let blocks = store.state.dom.blocks
        let limit = min(max(1, maxBlocksWhenFolded), blocks.count)
        return (
            store.state.isFolded && blocks.count > maxBlocksWhenFolded ?
            Array(blocks[0..<limit]) :
            blocks
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                ForEach(visibleBlocks) { block in
                    BlockView(block: block).equatable()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                store.send(.requestEdit(url: store.state.url))
            }
            
            if (
                store.state.isFolded &&
                (
                    store.state.dom.blocks.count >
                    maxBlocksWhenFolded
                )
            ) {
                HStack {
                    Button(action: {
                        store.send(.setFolded(false))
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color.Sub.secondaryIcon)
                            .padding(8)
                    }
                    .background(Color.Sub.buttonBackground)
                    .cornerRadius(8)
                    .padding(.vertical, 4)

                    Spacer()
                }
                .padding(.bottom, 8)
                .padding(.top, 8)
                .padding(.leading, 16)
                .padding(.trailing, 16)
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView(
            store: ViewStore(
                state: ThreadModel(
                    url: URL(fileURLWithPath: "example.subtext"),
                    dom: Subtext(
                        markup:
                        """
                        # Overview

                        Evolution is a behavior that emerges in any system with:

                        - Mutation
                        - Heredity
                        - Selection

                        Evolutionary systems often generate unexpected solutions. Nature selects for good enough.

                        > There is no such thing as advantageous in a general sense. There is only advantageous for the circumstances you’re living in. (Olivia Judson, Santa Fe Institute)

                        Evolving systems exist in punctuated equilibrium.

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
    }
}
