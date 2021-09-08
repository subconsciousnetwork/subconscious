//
//  SubtextEditableBlockView.swift
//  SubtextEditableBlockView
//
//  Created by Gordon Brander on 8/25/21.
//

import SwiftUI
import Combine
import Elmo
import os

struct SubtextEditableBlockView: View, Equatable {
    enum Action {
        case setFocus(Bool)
        case setSelection(NSRange)
        case setMarkup(String)
        case appendMarkup(String)
        case insertBreak(NSRange)
        case deleteBreak(NSRange)
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
        case .appendMarkup(let markup):
            state.dom = state.dom.appending(markup: markup)
        case .setFocus(let isFocused):
            state.isFocused = isFocused
        case .setSelection(let selection):
            state.selection = selection
        case .insertBreak, .deleteBreak:
            let action = String(reflecting: action)
            environment.debug(
                """
                Action should be handled by parent.\t\(action).
                Inserts and deletes cross multiple blocks, so they need to be
                coordinated by parent component.
                """
            )
        }
        return Empty().eraseToAnyPublisher()
    }

    var store: ViewStore<Model, Action>
    var fixedWidth: CGFloat
    var padding: CGFloat = 8

    var body: some View {
        LineTextViewRepresentable(
            text: Binding(
                get: { store.state.dom.markup },
                set: { markup in
                    store.send(.setMarkup(markup))
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
            shouldChange: shouldChange,
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

    func shouldChange(
        view: UITextView,
        shouldChangeTextIn nsRange: NSRange,
        replacementText: String
    ) -> Bool {
        if let range = Range(nsRange, in: view.text) {
            // User hit enter in block.
            // This could be at the beginning of text, middle of text.
            if (replacementText == "\n") {
                store.send(.insertBreak(nsRange))
                return false
            // User hit delete in empty block, or at beginning of block.
            } else if (
                replacementText == "" &&
                nsRange.location == 0 &&
                nsRange.length == 0
            ) {
                store.send(.deleteBreak(nsRange))
                return false
            // User pasted text containing newline.
            // Sanitize by removing newlines and append.
            } else if replacementText.contains("\n") {
                let clean = replacementText.replacingOccurrences(
                    of: "\n",
                    with: " "
                )
                view.text.replaceSubrange(range, with: clean)
                view.invalidateIntrinsicContentSize()
                return false
            }
            return true
        } else {
            return true
        }
    }
}

struct EditableSubtextBlock_Previews: PreviewProvider {
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
