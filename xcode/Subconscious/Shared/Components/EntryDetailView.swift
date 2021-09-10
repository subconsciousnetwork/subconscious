//
//  EntryDetailView.swift
//  EntryDetailView
//
//  Created by Gordon Brander on 9/9/21.
//

import SwiftUI
import Combine
import os
import Elmo

struct EntryDetailView: View, Equatable {
    enum Action {
        case editor(SubtextEditorView.Action)
    }

    static func tagEditor(
        _ action: SubtextEditorView.Action
    ) -> Action {
        .editor(action)
    }

    struct Model: Equatable {
        var editor = SubtextEditorView.Model()
    }

    static func update(
        state: inout Model,
        action: Action,
        environment: Logger
    ) -> AnyPublisher<Action, Never> {
        switch action {
        case .editor(let action):
            return SubtextEditorView.update(
                state: &state.editor,
                action: action,
                environment: environment
            ).map(tagEditor).eraseToAnyPublisher()
        }
    }

    var store: ViewStore<Model, Action>

    var body: some View {
        VStack {
            GeometryReader { geometry in
                SubtextEditorView(
                    store: ViewStore(
                        state: store.state.editor,
                        send: store.send,
                        tag: Self.tagEditor
                    ),
                    fixedWidth: geometry.size.width
                )
            }
            // TODO list of entry summaries
        }
    }
}

struct EntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EntryDetailView(
            store: ViewStore(
                state: .init(editor: .init()),
                send: { action in }
            )
        )
    }
}
