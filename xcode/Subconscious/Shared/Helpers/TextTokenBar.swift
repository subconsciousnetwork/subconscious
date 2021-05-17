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

struct TextTokenBarModel: Equatable {
    var tokens: [String] = []
}

func updateTextTokenBar(
    state: inout TextTokenBarModel,
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


struct TextTokenBarView: View, Equatable {
    let store: ViewStore<TextTokenBarModel, TextTokenBarAction>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(store.state.tokens, id: \.self) { text in
                    Button(
                        action: {
                            store.send(.select(text: text))
                        },
                        label: {
                            TextTokenView(text: text)
                        }
                    )
                    .foregroundColor(.Subconscious.text)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct TextTokenBarView_Previews: PreviewProvider {
    static var previews: some View {
        TextTokenBarView(
            store: ViewStore(
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
        )
    }
}
