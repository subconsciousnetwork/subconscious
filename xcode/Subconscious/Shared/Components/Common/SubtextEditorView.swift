//
//  SubtextEditorView.swift
//  SubtextEditorView
//
//  Created by Gordon Brander on 8/25/21.
//

import SwiftUI
import Combine
import Elmo
import os

struct SubtextEditorView: View, Equatable {
    enum Action {
        case setFocus(Bool)
        case setSelection(NSRange)
        case setMarkup(String)
    }

    struct Model: Equatable, Identifiable {
        var id = UUID()
        var dom: Subtext3
        var selection: NSRange = NSMakeRange(0, 0)
        var isFocused: Bool = false

        init(dom: Subtext3) {
            self.dom = dom
        }

        init(markup: String = "") {
            self.dom = Subtext3(markup)
        }

        mutating func append(_ model: Model) {
            self.dom = self.dom.appending(dom: model.dom)
        }
    }

    static func update(
        state: inout Model,
        action: Action,
        environment: Logger
    ) -> AnyPublisher<Action, Never> {
        switch action {
        case .setMarkup(let markup):
            state.dom = Subtext3(markup)
        case .setFocus(let isFocused):
            state.isFocused = isFocused
        case .setSelection(let selection):
            state.selection = selection
        }
        return Empty().eraseToAnyPublisher()
    }

    var store: ViewStore<Model, Action>
    var fixedWidth: CGFloat
    var padding: CGFloat = 8

    var body: some View {
        LineTextViewRepresentable(
            attributedText: Binding(
                get: {
                    store.state.dom.renderMarkup(url: { sub in
                        SubURL.wikilinkToURLString(sub)
                    })
                },
                set: { markup in
                    store.send(.setMarkup(markup.string))
                }
            ),
            isFocused: Binding(
                get: { store.state.isFocused },
                set: { isFocused in
                    store.send(.setFocus(isFocused))
                }
            ),
            selection: Binding(
                get: { store.state.selection },
                set: { selection in
                    store.send(.setSelection(selection))
                }
            ),
            fixedWidth: fixedWidth - (padding * 2)
        )
        .padding(.vertical, padding)
        .padding(.horizontal, padding)
        .background(
              store.state.isFocused
            ? Constants.Color.secondaryBackground
            : Constants.Color.background
        )
        .cornerRadius(8)
    }
}

struct SubtextEditorView_Preview: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            SubtextEditableBlockView(
                store: ViewStore(
                    state: .init(),
                    send: { action in
                        print(action)
                    }
                ),
                fixedWidth: geometry.size.width
            )
        }
    }
}
