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
        case setFirstResponder(Bool)
        case setSelection(NSRange)
        case setMarkup(String)
        case append
        case prepend
        case remove
        case split(at: NSRange)
        case mergeUp
    }

    struct Model: Equatable, Identifiable {
        var id = UUID()
        var dom: Subtext3
        var selection: NSRange = NSMakeRange(0, 0)
        var isFirstResponder: Bool = false

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
        case .setFirstResponder(let isFirstResponder):
            state.isFirstResponder = isFirstResponder
        case .setSelection(let selection):
            state.selection = selection
        case .append:
            environment.debug(
                """
                .append should be handled by parent.
                """
            )
        case .prepend:
            environment.debug(
                """
                .prepend should be handled by parent.
                """
            )
        case .remove:
            environment.debug(
                """
                .remove should be handled by parent.
                """
            )
        case .mergeUp:
            environment.debug(
                """
                .mergeUp should be handled by parent.
                """
            )
        case .split:
            environment.debug(
                """
                .split should be handled by parent.
                """
            )
        }
        return Empty().eraseToAnyPublisher()
    }

    var store: ViewStore<Model, Action>
    var fixedWidth: CGFloat
    var padding: CGFloat = 8

    var body: some View {
//        if !store.state.isEditing {
//            Text(
//                AttributedString(
//                    store.state.dom.renderMarkup(
//                        url: SubURL.wikilinkToURLString
//                    )
//                )
//            ).onTapGesture(perform: {
//                store.send(.setEditing(true))
//            })
//        } else {
            LineTextViewRepresentable(
                text: Binding(
                    get: { store.state.dom.markup },
                    set: { markup in
                        store.send(.setMarkup(markup))
                    }
                ),
                shouldChange: shouldChange,
                onBeginEditing: onBeginEditing,
                onEndEditing: onEndEditing,
                fixedWidth: fixedWidth - (padding * 2)
            )
            .padding(.vertical, padding)
            .padding(.horizontal, padding)
            .background(
                  store.state.isFirstResponder
                ? Constants.Color.secondaryBackground
                : Constants.Color.background
            )
            .cornerRadius(8)
//        }
    }

    func shouldChange(
        view: UITextView,
        shouldChangeTextIn nsRange: NSRange,
        replacementText: String
    ) -> Bool {
        if let range = Range(nsRange, in: view.text) {
            // User hit enter at begginging of text.
            // Prepend new block before.
            if (
                replacementText == "\n" &&
                nsRange.length == 0 &&
                nsRange.location == 0
            ) {
                store.send(.prepend)
                return false
            // User hit enter at end of text.
            // Append new block after.
            } else if (
                replacementText == "\n" &&
                nsRange.length == 0 &&
                range.upperBound == view.text.endIndex
            ) {
                view.resignFirstResponder()
                store.send(.append)
                return false
            // User hit enter in middle of text.
            // Split block at location.
            } else if (
                replacementText == "\n" &&
                nsRange.length == 0 &&
                range.lowerBound > view.text.startIndex &&
                range.upperBound < view.text.endIndex
            ) {
                view.resignFirstResponder()
                store.send(.split(at: nsRange))
                return false
            // User hit delete in empty block.
            // Remove block.
            } else if (
                replacementText == "" &&
                view.text == "" &&
                nsRange.location == 0 &&
                nsRange.length == 0
            ) {
                view.resignFirstResponder()
                store.send(.remove)
                return true
            // User hit delete with cursor at beginning of block.
            // Merge block with block above.
            } else if (
                replacementText == "" &&
                nsRange.location == 0 &&
                nsRange.length == 0
            ) {
                view.resignFirstResponder()
                store.send(.mergeUp)
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

    func onBeginEditing(_ text: String) {
        withAnimation(.easeOut(duration: Constants.Duration.fast)) {
            store.send(.setFirstResponder(true))
        }
    }

    func onEndEditing(_ text: String) {
        withAnimation(.easeOut(duration: Constants.Duration.fast)) {
            store.send(.setFirstResponder(false))
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
