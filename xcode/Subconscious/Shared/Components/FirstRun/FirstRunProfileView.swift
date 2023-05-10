//
//  FirstRunProfileView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//

import SwiftUI
import ObservableStore

struct FirstRunProfileView: View {
    @ObservedObject var app: Store<AppModel>
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let did = Did(app.state.sphereIdentity ?? "") ?? Config.default.subconsciousGeistDid
        NavigationStack {
            VStack(spacing: AppTheme.padding) {
                Spacer()
                StackedGlowingImage(
                    width: 180,
                    height: 180
                ) {
                    GenerativeProfilePic(
                        did: did,
                        size: 180
                    )
                }
                
                Text("This is your sphere. It stores your notes.")
                    .foregroundColor(.secondary)
                Spacer()
                Text("What should we name it?")
                        .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: AppTheme.unit4) {
                    ValidatedTextField(
                        placeholder: "my-nickname",
                        text: Binding(
                            get: { app.state.nicknameFormFieldValue },
                            send: app.send,
                            tag: AppAction.setNickname
                        ),
                        caption: "This is how others will see you. Lowercase letters, numbers and dashes only.",
                        hasError: !app.state.isNicknameFormFieldValid
                    )
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .shadow(
                        color: AppTheme.onboarding
                            .shadow(colorScheme).opacity(0.5),
                        radius: AppTheme.onboarding.shadowSize
                    )
                }
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunCreateSphereView(app: app)
                    },
                    label: {
                        Text("Continue")
                    }
                )
                .buttonStyle(PillButtonStyle())
                .disabled(!app.state.isNicknameFormFieldValid)
            }
            .padding()
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                AppTheme.onboarding
                    .appBackgroundGradient(colorScheme)
            )
        }
    }
}

struct FirstRunProfileView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunProfileView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
