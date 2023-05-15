//
//  FirstRunRecoveryView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 11/5/2023.
//

import ObservableStore
import SwiftUI

struct FirstRunRecoveryView: View {
    @ObservedObject var app: Store<AppModel>
    @Environment(\.colorScheme) var colorScheme
    
    var did: Did? {
        Did(app.state.sphereIdentity ?? "")
    }
    
    var body: some View {
        VStack(spacing: AppTheme.padding) {
            Spacer()
        
            Text("This is your secret recovery phrase. You can use it to recover your data if you lose access.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            RecoveryPhraseView(
                state: app.state.recoveryPhrase,
                send: Address.forward(
                    send: app.send,
                    tag: AppRecoveryPhraseCursor.tag
                )
            )
            .shadow(
                color: AppTheme.onboarding
                    .shadow(colorScheme).opacity(0.5),
                radius: AppTheme.onboarding.shadowSize
            )
            
            Text("It's for your eyes only. We don't store it.\n Write it down or add it to your password manager. Keep it secret, keep it safe.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            NavigationLink(
                value: FirstRunStep.connect,
                label: {
                    Text("Ok, I wrote it down")
                }
            )
            .buttonStyle(PillButtonStyle())
        }
        .padding()
        .background(
            AppTheme.onboarding
                .appBackgroundGradient(colorScheme)
        )
        .navigationTitle("Recovery Phrase")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstRunRecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunRecoveryView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
