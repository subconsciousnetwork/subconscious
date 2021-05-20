//
//  PostHeader.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/8/21.
//

import SwiftUI
import Combine

struct PostHeaderModel {
    var name: String
}

enum PostHeaderAction {
    case tapProfile
}

func updatePostHeader(
    state: inout PostHeaderModel,
    action: PostHeaderAction,
    environment: AppEnvironment
) -> AnyPublisher<PostHeaderAction, Never> {
    switch action {
    case .tapProfile:
        environment.logger.warning(
            """
            PostHeaderAction.tapProfile
            action should be handled by parent
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

struct PostHeaderView: View {
    var state: PostHeaderModel
    var send: (PostHeaderAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(state.name)
                    .fontWeight(.semibold)
                Spacer()
                Icon(image: Image(systemName: "chevron.down"))
                    .foregroundColor(Color.Subconscious.secondaryIcon)
            }
            .frame(width: .infinity, height: 40, alignment: .leading)
            .padding(.horizontal, 16)
            Divider()
        }
    }
}

struct PostHeader_Previews: PreviewProvider {
    static var previews: some View {
        PostHeaderView(
            state: PostHeaderModel(
                name: "Alec Smith"
            ),
            send: { action in }
        )
    }
}
