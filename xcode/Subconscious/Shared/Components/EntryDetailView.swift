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
        case commitQuery(String)
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
        case .commitQuery:
            let string = String(reflecting: action)
            environment.debug(
                """
                Action should be handled by parent component.\t\(string)
                """
            )
        }
        return Empty().eraseToAnyPublisher()
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
                            top: 16,
                            left: 16,
                            bottom: 16,
                            right: 16
                        )
                    )
                    Divider()
                    VStack {
                        ForEach(store.state.backlinks) { fileEntry in
                            Button(
                                action: {
                                    store.send(.commitQuery(fileEntry.title))
                                },
                                label: {
                                    EntrySummaryView(
                                        state: .init(dom: fileEntry.dom)
                                    )
                                    .equatable()
                                    .foregroundColor(Constants.Color.text)
                                    .padding(.leading, 0)
                                    .padding(.trailing, 16)
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                }
                            )
                            Divider()
                        }
                    }.padding(.leading, 16)
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
