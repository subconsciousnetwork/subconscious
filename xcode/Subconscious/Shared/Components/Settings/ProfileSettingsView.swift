//
//  GatewaySettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore

struct ProfileSettingsView: View {
    @ObservedObject var app: Store<AppModel>
    
    @State var txt: String = ""

    var body: some View {
        Form {
            Section {
                ValidatedTextField(
                    placeholder: "nickname",
                    text: Binding(
                        get: { app.state.nicknameFormFieldValue },
                        send: app.send,
                        tag: AppAction.setNickname
                    ),
                    caption: "Lowercase letters, numbers, and dashes only"
//                    hasError: !app.state.isNicknameFormFieldValid
                )
                .formField()
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .autocapitalization(.none)
            }
        }
        .formStyle(.automatic)
        .navigationTitle("Nickname")
    }
}

struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
