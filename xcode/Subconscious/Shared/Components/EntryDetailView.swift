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
        var backlinks: [FileEntry] = []

        init(
            markup: String = "",
            backlinks: [FileEntry] = []
        ) {
            self.editor = .init(markup: markup)
            self.backlinks = backlinks
        }
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
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    SubtextEditorView(
                        store: ViewStore(
                            state: store.state.editor,
                            send: store.send,
                            tag: Self.tagEditor
                        ),
                        fixedWidth: geometry.size.width,
                        textContainerInset: .init(
                            top: 8,
                            left: 8,
                            bottom: 8,
                            right: 8
                        )
                    )
                    VStack(spacing: 8) {
                        ForEach(store.state.backlinks) { fileEntry in
                            TranscludeView(
                                state: .init(dom: fileEntry.dom)
                            ).equatable()
                        }
                    }.padding(8)
                }
            }
        }
    }
}

struct EntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EntryDetailView(
            store: ViewStore(
                state: .init(),
                send: { action in }
            )
        )
    }
}
