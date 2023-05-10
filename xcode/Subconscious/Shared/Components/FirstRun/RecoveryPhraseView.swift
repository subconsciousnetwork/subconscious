//
//  RecoveryPhraseView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore
import os

struct RecoveryPhraseView: View {
    var state: RecoveryPhraseModel
    var send: (RecoveryPhraseAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(state.phrase)
                    .monospaced()
                    .textSelection(.enabled)
                Spacer()
            }
            .padding()
            .background(.background)
            Button(
                action: {
                    send(.copy)
                },
                label: {
                    if !state.didCopy {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy to clipboard")
                        }
                        .transition(
                            .asymmetric(
                                insertion: .identity,
                                removal: .move(
                                    edge: .top
                                ).combined(
                                    with: .opacity
                                )
                            )
                        )
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Copied!")
                        }
                        .transition(.opacity)
                    }
                }
            )
            .buttonStyle(BarButtonStyle())
        }
        .clipShape(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLg)
                .stroke(Color.separator, lineWidth: 0.5)
        )
    }
}

enum RecoveryPhraseAction: Hashable {
    case setPhrase(_ phrase: String)
    case copy
}

struct RecoveryPhraseModel: ModelProtocol {
    var phrase: String = ""
    var didCopy: Bool = false

    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "RecoveryPhrase"
    )

    static func update(
        state: RecoveryPhraseModel,
        action: RecoveryPhraseAction,
        environment: RecoveryPhraseEnvironment
    ) -> Update<RecoveryPhraseModel> {
        switch action {
        case .setPhrase(let phrase):
            var model = state
            model.phrase = phrase
            return Update(state: model)
        case .copy:
            // Copy to clipboard
            environment.pasteboard.string = state.phrase
            logger.log("Copied recovery phrase to clipboard")
            var model = state
            model.didCopy = true
            return Update(state: model)
                .animation(.default)
        }
    }
}

struct RecoveryPhraseEnvironment {
    // Pasteboard is defined as a protocol. This allows us to mock for testing.
    var pasteboard: PasteboardProtocol = UIPasteboard.general
}

struct RecoveryPhraseView_Previews: PreviewProvider {
    struct TestView: View {
        @StateObject private var store = Store(
            state: RecoveryPhraseModel(
                phrase: "foo bar baz bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom"
            ),
            environment: RecoveryPhraseEnvironment()
        )

        var body: some View {
            RecoveryPhraseView(
                state: store.state,
                send: store.send
            )
        }
    }

    static var previews: some View {
        TestView()
    }
}
