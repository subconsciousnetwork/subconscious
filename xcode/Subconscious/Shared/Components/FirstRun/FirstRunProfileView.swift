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
        NavigationStack {
            VStack(spacing: AppTheme.padding) {
                Spacer()
                Text("What should we call you?")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: AppTheme.unit4) {
                    ValidatedTextField(
                        alignment: .center,
                        placeholder: "nickname",
                        text: Binding(
                            get: { app.state.nicknameFormFieldValue },
                            send: app.send,
                            tag: AppAction.setNickname
                        ),
                        onFocusChanged: { focused in
                            app.send(.nicknameFormField(.focusChange(focused: focused)))
                        },
                        caption: "Lowercase letters, numbers and dashes only.",
                        hasError: !app.state.isNicknameFormFieldValid
                    )
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .shadow(
                        color: AppTheme.onboarding
                            .shadow(colorScheme).opacity(1),
                        radius: AppTheme.onboarding.shadowSize
                    )
                }
                
                Spacer()
                
                if !app.state.nicknameFormField.hasFocus {
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
