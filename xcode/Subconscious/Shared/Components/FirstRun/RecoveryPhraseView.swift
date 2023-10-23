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
                Text(verbatim: state.phrase?.mnemonic ?? "")
                    .monospaced()
                    .textSelection(.enabled)
                Spacer()
            }
            .padding()
            .background(.background)
            
            ShareLink(item: state.phrase?.mnemonic ?? "") {
                Label(
                    "Share",
                    systemImage: "square.and.arrow.up"
                )
            }
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
    case setPhrase(_ phrase: RecoveryPhrase?)
}

struct RecoveryPhraseModel: ModelProtocol {
    var phrase: RecoveryPhrase?

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
        }
    }
}

typealias RecoveryPhraseEnvironment = Void

struct RecoveryPhraseView_Previews: PreviewProvider {
    struct TestView: View {
        @StateObject private var store = Store(
            state: RecoveryPhraseModel(
                phrase: RecoveryPhrase("foo bar baz bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom bim blap blap")
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
