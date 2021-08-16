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
    case saveCreate(DraftEntry)
    case saveCreateSuccess(FileEntry)
    case saveUpdate(FileEntry)
    case saveUpdateSuccess(FileEntry)
    case cancel
    case failure(message: String)
    static let clear = set(url: nil, body: "")
}


//  MARK: State
struct EditorModel: Equatable {
    var attributedBody: NSAttributedString {
        let attributedString = Subtext2(markup: body).renderMarkupAttributedString(url: {
            url in URL(string: "http://example.com")
        })
        return NSAttributedString(attributedString)
    }
    var url: URL?
    var body = ""
}

//  MARK: Reducer
func updateEditor(
    state: inout EditorModel,
    action: EditorAction,
    environment: IOService
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
            .map({ fileEntry in
                .set(
                    url: fileEntry.url,
                    body: fileEntry.content
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
                    FileEntry(
                        url: url,
                        content: state.body
                    )
                )
            ).eraseToAnyPublisher()
        } else {
            return Just(
                .saveCreate(
                    DraftEntry(
                        content: state.body
                    )
                )
            ).eraseToAnyPublisher()
        }
    case .saveCreate(let draft):
        return environment.database.createEntry(draft)
            .map({ fileEntry in
                .saveCreateSuccess(fileEntry)
            })
            .catch({ error in
                Just(.failure(message: error.localizedDescription))
            })
            .eraseToAnyPublisher()
    case .saveCreateSuccess(let fileEntry):
        environment.logger.log(
            "Created entry \(fileEntry.url)"
        )
        return Just(.clear).eraseToAnyPublisher()
    case .saveUpdate(let fileEntry):
        return environment.database.writeEntry(fileEntry)
            .map({ fileEntry in
                .saveUpdateSuccess(fileEntry)
            })
            .catch({ error in
                Just(.failure(message: error.localizedDescription))
            })
            .eraseToAnyPublisher()
    case .saveUpdateSuccess(let fileEntry):
        environment.logger.log(
            "Updated entry \(fileEntry.url)"
        )
        return Just(.clear).eraseToAnyPublisher()
    case .cancel:
        // Delay for a bit. Should clear just after sheet animation completes.
        // Note that SwiftUI animations don't yet have reasonable
        // onComplete handlers, so we're making do.
        return Just(EditorAction.clear).delay(
            for: .milliseconds(10),
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
            AttributedTextViewRepresentable(
                attributedText: Binding(
                    get: { store.state.attributedBody },
                    set: { attributedText in
                        store.send(.setBody(attributedText.string))
                    }
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
