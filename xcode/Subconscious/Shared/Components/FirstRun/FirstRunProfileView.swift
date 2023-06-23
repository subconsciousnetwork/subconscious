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
                ValidatedFormField(
                    alignment: .center,
                    placeholder: "nickname",
                    field: app.state.nicknameFormField,
                    send: Address.forward(
                        send: app.send,
                        tag: AppAction.nicknameFormField
                    ),
                    caption: Text("Lowercase letters, numbers and dashes only."),
                    autoFocus: true,
                    submitLabel: .go,
                    onSubmit: {
                        app.send(.submitFirstRunProfileStep)
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
                Button(action: {
                    app.send(.submitFirstRunProfileStep)
                }, label: {
                    Text("Continue")
                })
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
