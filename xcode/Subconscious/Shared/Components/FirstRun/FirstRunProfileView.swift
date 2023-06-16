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
        VStack(spacing: AppTheme.padding) {
            Spacer()
            Text("What should we call you?")
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: AppTheme.unit4) {
                ValidatedFormField<Petname.Name, AppModel>(
                    alignment: .center,
                    placeholder: "nickname",
                    field: app.state.nicknameFormField,
                    send: app.send,
                    tag: AppAction.nicknameFormField,
                    caption: "Lowercase letters, numbers and dashes only.",
                    autoFocus: true,
                    submitLabel: .go,
                    onSubmit: {
                        if app.state.nicknameFormField.isValid {
                            app.send(.pushFirstRunStep(.sphere))
                        }
                    }
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
                    value: FirstRunStep.sphere,
                    label: {
                        Text("Continue")
                    }
                )
                .buttonStyle(PillButtonStyle())
                .disabled(!app.state.nicknameFormField.isValid)
            }
        }
        .padding()
        .navigationTitle("Your Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            AppTheme.onboarding
                .appBackgroundGradient(colorScheme)
        )
        .onAppear {
            app.send(.createSphere)
        }
        .onDisappear {
            guard let nickname = app.state.nicknameFormField.validated else {
                return
            }
            
            app.send(.submitNickname(nickname))
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
