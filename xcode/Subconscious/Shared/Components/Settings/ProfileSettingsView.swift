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
    
    var body: some View {
        Form {
            Section {
                ValidatedFormField<Petname.Name, AppModel>(
                    placeholder: "nickname",
                    field: app.state.nicknameFormField,
                    send: app.send,
                    tag: AppAction.nicknameFormField,
                    caption: "Lowercase letters, numbers and dashes only."
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .onDisappear {
                    guard let nickname = app.state.nicknameFormField.validated else {
                        return
                    }
                    
                    app.send(.persistNickname(nickname))
                }
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
