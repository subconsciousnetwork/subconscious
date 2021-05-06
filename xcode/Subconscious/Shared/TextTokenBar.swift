//
//  TextTokenBar.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/6/21.
//

import SwiftUI

enum TextTokenBarAction {
    case select(text: String)
}

struct TextTokenBarView: View {
    var tokens: [String]
    var send: (TextTokenBarAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tokens, id: \.self) { text in
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
            .padding()
        }
    }
}

struct TextTokenBarView_Previews: PreviewProvider {
    static var previews: some View {
        TextTokenBarView(
            tokens: [
                "#log",
                "#idea",
                "#pattern",
                "#quote",
                "#project",
                "#decision"
            ],
            send: { action in }
        )
    }
}
