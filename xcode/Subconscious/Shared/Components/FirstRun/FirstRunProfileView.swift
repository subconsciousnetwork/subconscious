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

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: AppTheme.unit4) {
                    ValidatedTextField(
                        placeholder: "nickname",
                        text: Binding(
                            get: { app.state.nicknameFormFieldValue },
                            send: app.send,
                            tag: AppAction.setNickname
                        ),
                        caption: "Lowercase letters, numbers and dashes only.",
                        hasError: !app.state.isNicknameFormFieldValid
                    )
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
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
                .simultaneousGesture(TapGesture().onEnded {
                    app.send(.createSphere)
                })
                .disabled(!app.state.nicknameFormField.isValid)
            }
            .padding()
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
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
