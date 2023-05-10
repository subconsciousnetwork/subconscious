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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .center, spacing: AppTheme.padding * 2) {
                    Text("This is your secret recovery phrase. You can use it to recover your data if you lose access.")
                        .foregroundColor(.secondary)
                    RecoveryPhraseView(
                        state: app.state.recoveryPhrase,
                        send: Address.forward(
                            send: app.send,
                            tag: AppRecoveryPhraseCursor.tag
                        )
                    )
                    .shadow(
                        color: OnboardingTheme.shadow(colorScheme).opacity(0.5),
                        radius: OnboardingTheme.shadowSize
                    )
                    
                    VStack(alignment: .leading, spacing: AppTheme.unit2) {
                        Text("It's for your eyes only. We don't store it. Write it down or add it to your password manager. Keep it secret, keep it safe.")
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
                .buttonStyle(PillButtonStyle())
            }
            .padding()
            .background(
                OnboardingTheme.appBackgroundGradient(colorScheme)
            )
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
