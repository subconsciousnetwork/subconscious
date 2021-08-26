//
//  EditableSubtextBlockView.swift
//  EditableSubtextBlockView
//
//  Created by Gordon Brander on 8/25/21.
//

import SwiftUI
import Combine
import Elmo

struct EditableSubtextBlockView: View, Equatable {
    enum Action {
        case setEditing(Bool)
        case setMarkup(String)
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
        action: Action
    ) -> AnyPublisher<Action, Never> {
        switch action {
        case .setMarkup(let markup):
            state.dom = Subtext3(markup)
        case .setEditing(let isEditing):
            state.isEditing = isEditing
        }
        return Empty().eraseToAnyPublisher()
    }

    var store: ViewStore<Model, Action>
    var fixedWidth: CGFloat

    var body: some View {
        if !store.state.isEditing {
            Text(
                AttributedString(
                    store.state.dom.renderMarkup(
                        url: SubURL.wikilinkToURLString
                    )
                )
            ).onTapGesture(perform: {
                store.send(.setEditing(true))
            })
        } else {
            DynamicTextViewRepresentable(
                text: Binding(
                    get: { store.state.dom.markup },
                    set: { markup in
                        store.send(.setMarkup(markup))
                    }
                ),
                fixedWidth: fixedWidth
            )
        }
    }
}

struct EditableSubtextBlock_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            EditableSubtextBlockView(
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
