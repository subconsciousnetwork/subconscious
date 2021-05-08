//
//  ThreadView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/6/21.
//

import SwiftUI
import Combine

enum ThreadAction {
    case setFolded(_ isFolded: Bool)
    case requestEdit(_ document: SubconsciousDocument)
}

struct ThreadModel: Identifiable {
    var document: SubconsciousDocument
    var isFolded: Bool = true
    var id: Int {
        document.id
    }
}

func updateThread(
    state: inout ThreadModel,
    action: ThreadAction,
    environment: AppEnvironment
) -> AnyPublisher<ThreadAction, Never> {
    switch action {
    case .setFolded(let isFolded):
        state.isFolded = isFolded
    case .requestEdit:
        environment.logger.warning(
            """
            ThreadAction.requestEdit
            This action should have been handled by the parent view.
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

/// A foldable thread
struct ThreadView: View {
    var thread: ThreadModel
    var send: (ThreadAction) -> Void
    var maxBlocksWhenFolded = 2

    var body: some View {
        VStack(spacing: 0) {
            if !thread.document.title.isEmpty {
                Text(thread.document.title)
                    .font(.body)
                    .bold()
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }

            if (
                thread.document.content.blocks.count >
                maxBlocksWhenFolded && thread.isFolded
            ) {
                ForEach(thread.document.content.blocks[
                    0..<max(1, maxBlocksWhenFolded)
                ]) { block in
                    BlockView(block: block)
                }

                HStack {
                    Button(action: {
                        send(.setFolded(false))
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color.Subconscious.secondaryIcon)
                            .padding(8)
                    }
                    .background(Color.Subconscious.buttonBackground)
                    .cornerRadius(8)
                    .padding(.vertical, 4)

                    Spacer()
                }
                .padding(.bottom, 8)
                .padding(.top, 8)
                .padding(.leading, 16)
                .padding(.trailing, 16)
            } else {
                ForEach(thread.document.content.blocks) { block in
                    BlockView(block: block)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            send(.requestEdit(thread.document))
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView(
            thread: ThreadModel(
                document: SubconsciousDocument(
                    title: "",
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
    }
}
