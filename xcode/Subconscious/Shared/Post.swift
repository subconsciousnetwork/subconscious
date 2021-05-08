//
//  Post.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/8/21.
//

import SwiftUI
import Combine

struct PostModel {
    var header: PostHeaderModel
    var thread: ThreadModel
}

enum PostAction {
    case thread(_ action: ThreadAction)
    case header(_ action: PostHeaderAction)
}

func updatePost(
    state: inout PostModel,
    action: PostAction,
    environment: AppEnvironment
) -> AnyPublisher<PostAction, Never> {
    switch action {
    case .header(let action):
        return updatePostHeader(
            state: &state.header,
            action: action,
            environment: environment
        ).map(tagPostHeader).eraseToAnyPublisher()
    case .thread(let action):
        return updateThread(
            state: &state.thread,
            action: action,
            environment: environment
        ).map(tagPostThread).eraseToAnyPublisher()
    }
    return Empty().eraseToAnyPublisher()
}

func tagPostHeader(_ action: PostHeaderAction) -> PostAction {
    switch action {
    default:
        return .header(action)
    }
}

func tagPostThread(_ action: ThreadAction) -> PostAction {
    switch action {
    default:
        return .thread(action)
    }
}

/// PostViews are threads wrapped in information about who/where the thread is from.
struct PostView: View {
    var state: PostModel
    var send: (PostAction) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            PostHeaderView(
                state: state.header,
                send: address(
                    send: send,
                    tag: tagPostHeader
                )
            )
            ThreadView(
                thread: state.thread,
                send: address(send: send, tag: tagPostThread)
            )
        }
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(
            state: PostModel(
                header: PostHeaderModel(
                    name: "Concept Collider"
                ),
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
                )
            ),
            send: { action in }
        )
    }
}
