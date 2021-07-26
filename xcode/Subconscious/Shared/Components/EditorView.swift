//
//  Editor.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/27/21.
//

import Foundation
import Combine
import SwiftUI
import os
import Elmo

//  MARK: Actions
enum EditorAction {
    /// Set editor properties
    case set(url: URL?, body: String)
    case setBody(String)
    /// Edit content
    case editCreate(content: String)
    case editUpdate(url: URL)
    case save
    case saveCreate(Entry)
    case saveCreateSuccess(EntryFile)
    case saveUpdate(EntryFile)
    case saveUpdateSuccess(EntryFile)
    case cancel
    case failure(message: String)
    static let clear = set(url: nil, body: "")
}


//  MARK: State
struct EditorModel: Equatable {
    var url: URL?
    var body = ""
}

//  MARK: Environment
struct EditorService {
    var logger: Logger
    var database: DatabaseEnvironment
}

//  MARK: Reducer
func updateEditor(
    state: inout EditorModel,
    action: EditorAction,
    environment: EditorService
) -> AnyPublisher<EditorAction, Never> {
    switch action {
    case .failure(let message):
        //  TODO show user warnings
        environment.logger.warning("\(message)")
    case .set(let url, let body):
        state.url = url
        state.body = body
    case .setBody(let body):
        state.body = body
    case .editUpdate(let url):
        return environment.database.readEntry(url: url)
            .map({ entryFile in
                .set(
                    url: entryFile.url,
                    body: entryFile.entry.content
                )
            })
            .catch({ error in
                Just(
                    .failure(message: error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
    case .editCreate(let body):
        return Just(.set(url: nil, body: body)).eraseToAnyPublisher()
    case .save:
        if let url = state.url {
            return Just(
                .saveUpdate(
                    EntryFile(
                        url: url,
                        content: state.body
                    )
                )
            ).eraseToAnyPublisher()
        } else {
            return Just(
                .saveCreate(
                    Entry(
                        content: state.body
                    )
                )
            ).eraseToAnyPublisher()
        }
    case .saveCreate(let entry):
        return environment.database.createEntry(entry)
            .map({ entryFile in
                .saveCreateSuccess(entryFile)
            })
            .catch({ error in
                Just(.failure(message: error.localizedDescription))
            })
            .eraseToAnyPublisher()
    case .saveCreateSuccess(let entryFile):
        environment.logger.log(
            "Created entry \(entryFile.url)"
        )
        return Just(.clear).eraseToAnyPublisher()
    case .saveUpdate(let entryFile):
        return environment.database.writeEntry(entryFile)
            .map({ entryFile in
                .saveUpdateSuccess(entryFile)
            })
            .catch({ error in
                Just(.failure(message: error.localizedDescription))
            })
            .eraseToAnyPublisher()
    case .saveUpdateSuccess(let entryFile):
        environment.logger.log(
            "Updated entry \(entryFile.url)"
        )
        return Just(.clear).eraseToAnyPublisher()
    case .cancel:
        // Delay for a bit. Should clear just after sheet animation completes.
        // Note that SwiftUI animations don't yet have reasonable
        // onComplete handlers, so we're making do.
        return Just(EditorAction.clear).delay(
            for: .milliseconds(500),
            scheduler: RunLoop.main
        ).eraseToAnyPublisher()
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: View
struct EditorView: View, Equatable {
    let store: ViewStore<EditorModel, EditorAction>
    let save: LocalizedStringKey = "Save"
    let cancel: LocalizedStringKey = "Cancel"
    let edit: LocalizedStringKey = "Edit"
    let titlePlaceholder: LocalizedStringKey = "Title:"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(cancel) {
                    store.send(.cancel)
                }
                Spacer()
                Button(action: {
                    store.send(.save)
                }) {
                    Text(save).bold()
                }
            }
            .padding(16)
            Divider()
            TextViewRepresentable(
                text: Binding(
                    get: { store.state.body },
                    set: { text in store.send(.setBody(text)) }
                )
            )
            .insets(
                EdgeInsets(
                    top: 24,
                    leading: 16,
                    bottom: 24,
                    trailing: 16
                )
            )
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(
            store: ViewStore(state: EditorModel(), send: { action in })
        )
    }
}
