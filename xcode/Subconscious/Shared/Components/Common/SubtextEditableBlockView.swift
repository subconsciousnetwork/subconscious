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
        case setEditing(Bool)
        case setMarkup(String)
        case enter(selection: NSRange, text: String)
    }

    struct Model: Equatable, Identifiable {
        var id = UUID()
        var dom: Subtext3
        var isEditing: Bool = false

        init(dom: Subtext3) {
            self.dom = dom
        }
        
        init(markup: String = "") {
            self.dom = Subtext3(markup)
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
        case .setEditing(let isEditing):
            state.isEditing = isEditing
        case .enter:
            environment.debug(
                """
                .enter should be handled by parent.
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
                  store.state.isEditing
                ? Constants.Color.secondaryBackground
                : Constants.Color.background
            )
            .cornerRadius(8)
//        }
    }

    func shouldChange(
        view: UITextView,
        selection range: NSRange,
        text: String
    ) -> Bool {
        // If user hit enter
        if range.length == 0 && text == "\n" {
            view.resignFirstResponder()
            self.store.send(.enter(selection: range, text: text))
            return false
        // If user pasted text containing newline
        } else if text.contains("\n") {
            let clean = text.replacingOccurrences(
                of: "\n",
                with: " "
            )
            if let range = Range(range, in: view.text) {
                view.text.replaceSubrange(range, with: clean)
                view.invalidateIntrinsicContentSize()
                return false
            }
            return true
        }
        return true
    }

    func onBeginEditing(_ text: String) {
        withAnimation(.easeOut(duration: Constants.Duration.fast)) {
            store.send(.setEditing(true))
        }
    }

    func onEndEditing(_ text: String) {
        withAnimation(.easeOut(duration: Constants.Duration.fast)) {
            store.send(.setEditing(false))
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
