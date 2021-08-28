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
        case enter
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
                onEnter: onEnter,
                onEditingChange: onEditingChange,
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

    func onEnter() {
        store.send(.enter)
    }

    func onEditingChange(_ isEditing: Bool) {
        withAnimation(.easeOut(duration: Constants.Duration.fast)) {
            store.send(.setEditing(isEditing))
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
