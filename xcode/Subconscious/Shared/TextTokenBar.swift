//
//  TextTokenBar.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/6/21.
//

import SwiftUI
import Combine

enum TextTokenBarAction {
    case select(text: String)
    case setTokens(_ tokens: [String])
}

struct TextTokenBarState {
    var tokens: [String] = []
}

func updateTextTokenBar(
    state: inout TextTokenBarState,
    action: TextTokenBarAction,
    environment: BasicEnvironment
) -> AnyPublisher<TextTokenBarAction, Never> {
    switch action {
    case .setTokens(let tokens):
        state.tokens = tokens
    case .select:
        environment.logger.warning(
            """
            TextTokenBarAction.select
            action should be handled by parent
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}


struct TextTokenBarView: View {
    var state: TextTokenBarState
    var send: (TextTokenBarAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(state.tokens, id: \.self) { text in
                    Button(
                        action: {
                            send(.select(text: text))
                        },
                        label: {
                            TextTokenView(text: text)
                        }
                    )
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct TextTokenBarView_Previews: PreviewProvider {
    static var previews: some View {
        TextTokenBarView(
            state: .init(tokens: [
                "#log",
                "#idea",
                "#pattern",
                "#quote",
                "#project",
                "#decision"
            ]),
            send: { action in }
        )
    }
}
