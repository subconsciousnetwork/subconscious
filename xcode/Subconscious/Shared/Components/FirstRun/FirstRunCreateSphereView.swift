//
//  FirstRunCreateSphereView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//
import ObservableStore
import SwiftUI

struct FirstRunCreateSphereView: View {
    /// FirstRunView is a major view that manages its own state in a store.
    @ObservedObject var store: Store<FirstRunModel>
    var onDone: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .center, spacing: AppTheme.unit4) {
                    Text("Recovery Phrase")
                        .font(.headline)
                    RecoveryPhraseView(text: store.state.sphereMnemonic ?? "")
                    VStack(alignment: .leading, spacing: AppTheme.unit2) {
                        Text("This is your secret recovery phrase. You can use it to recover your data if you lose access.")
                            .foregroundColor(.secondary)
                        Text("This is for your eyes only. We don't store it. Write it down. Keep it secret, keep it safe.")
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunDoneView(store: store, onDone: onDone)
                    },
                    label: {
                        Text("Ok, I wrote it down")
                    }
                )
                .buttonStyle(LargeButtonStyle())
            }
            .padding()
        }
        .task {
            store.send(.createSphere)
        }
        .navigationTitle("Recovery Phrase")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstRunCreateSphereView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunCreateSphereView(
            store: Store(
                state: FirstRunModel(
                    sphereMnemonic: "foo bar baz bing bong boo biz boz bonk bink boop bop beep bleep bloop blorp blonk blink blip blop boom"
                ),
                environment: AppEnvironment.default
            ),
            onDone: { id in }
        )
    }
}
