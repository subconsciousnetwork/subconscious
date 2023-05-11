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
    
    var did: Did? {
        Did(app.state.sphereIdentity ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(spacing: AppTheme.unit4) {
                    if let name = app.state.nicknameFormField.validated ?? Petname("ben") {
                        HStack(spacing: 0) {
                            Text("Hi, ")
                                .foregroundColor(.secondary)
                            PetnameView(petname: name)
                            Text(".")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let did = did {
                        StackedGlowingImage(
                            width: 80,
                            height: 80
                        ) {
                            GenerativeProfilePic(
                                did: did,
                                size: 80
                            )
                        }
                    }
                    
                    Text("This is your sphere. It stores your data.")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: AppTheme.padding ) {
                    Text("If you ever lose access to it, you can use your secret recovery phrase to recover your data.")
                        .foregroundColor(.secondary)
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
                AppTheme.onboarding
                    .appBackgroundGradient(colorScheme)
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
