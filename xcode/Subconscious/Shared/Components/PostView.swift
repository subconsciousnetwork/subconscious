////
////  Post.swift
////  Subconscious (iOS)
////
////  Created by Gordon Brander on 5/8/21.
////
//
//import SwiftUI
//import Combine
//import os
//import Elmo
//
//enum PostAction {
//    case thread(_ action: EntryAction)
//    case header(_ action: PostHeaderAction)
//}
//
//struct PostModel {
//    var header: PostHeaderModel
//    var entry: EntryModel
//}
//
//func updatePost(
//    state: inout PostModel,
//    action: PostAction,
//    environment: Logger
//) -> AnyPublisher<PostAction, Never> {
//    switch action {
//    case .header(let action):
//        return updatePostHeader(
//            state: &state.header,
//            action: action,
//            environment: environment
//        ).map(tagPostHeader).eraseToAnyPublisher()
//    case .thread(let action):
//        return updateEntry(
//            state: &state.entry,
//            action: action,
//            environment: environment
//        ).map(tagEntry).eraseToAnyPublisher()
//    }
//}
//
//func tagPostHeader(_ action: PostHeaderAction) -> PostAction {
//    switch action {
//    default:
//        return .header(action)
//    }
//}
//
//func tagEntry(_ action: EntryAction) -> PostAction {
//    switch action {
//    default:
//        return .thread(action)
//    }
//}
//
///// PostViews are entries wrapped in information about who/where the thread is from.
//struct PostView: SwiftUI.View {
//    var state: PostModel
//    var send: (PostAction) -> Void
//    
//    var body: some SwiftUI.View {
//        VStack(spacing: 8) {
//            PostHeaderView(
//                state: state.header,
//                send: address(
//                    send: send,
//                    tag: tagPostHeader
//                )
//            )
//            EntryView(
//                store: ViewStore(
//                    state: state.entry,
//                    send: send,
//                    tag: tagEntry
//                )
//            ).equatable()
//        }
//    }
//}
//
//struct PostView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostView(
//            state: PostModel(
//                header: PostHeaderModel(
//                    name: "Concept Collider"
//                ),
//                entry: EntryModel(
//                    url: URL(fileURLWithPath: "example.subtext"),
//                    dom: Subtext(
//                        markup:
//                        """
//                        # Overview
//
//                        Evolution is a behavior that emerges in any system with:
//
//                        - Mutation
//                        - Heredity
//                        - Selection
//
//                        Evolutionary systems often generate unexpected solutions. Nature selects for good enough.
//
//                        > There is no such thing as advantageous in a general sense. There is only advantageous for the circumstances you’re living in. (Olivia Judson, Santa Fe Institute)
//
//                        Evolving systems exist in punctuated equilibrium.
//
//                        & punctuated-equilibrium.st
//
//                        # Questions
//
//                        - What systems (beside biology) exhibit evolutionary behavior? Remember, evolution happens in any system with mutation, heredity, selection.
//                        - What happens to an evolutionary system when you remove mutation? Heredity? Selection?
//                        - Do you see a system with one of these properties? How can you introduce the other two?
//
//                        # See also
//
//                        & https://en.wikipedia.org/wiki/Evolutionary_systems
//                        """
//                    )
//                )
//            ),
//            send: { action in }
//        )
//    }
//}
