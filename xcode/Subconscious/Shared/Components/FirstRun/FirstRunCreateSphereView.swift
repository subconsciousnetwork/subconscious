//
//  FirstRunCreateSphereView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//
import ObservableStore
import SwiftUI

struct FirstRunCreateSphereView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .center, spacing: AppTheme.unit4) {
                    Text("Recovery Phrase")
                        .font(.headline)
                    RecoveryPhraseView(text: app.state.sphereMnemonic ?? "")
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
                        FirstRunDoneView(app: app)
                    },
                    label: {
                        Text("Ok, I wrote it down")
                    }
                )
                .buttonStyle(LargeButtonStyle())
            }
            .padding()
        }
        .navigationTitle("Recovery Phrase")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstRunCreateSphereView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunCreateSphereView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
