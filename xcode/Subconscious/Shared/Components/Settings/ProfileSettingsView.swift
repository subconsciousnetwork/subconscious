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
    var isNicknameValid: Bool {
        (
            (app.state.nickname == app.state.nicknameTextField)
            && app.state.nickname != nil
        )
    }

    var body: some View {
        Form {
            Section(header: Text("Nickname")) {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    HStack {
                        TextField(
                            "nickname", text: Binding(
                                get: { app.state.nicknameTextField },
                                send: app.send,
                                tag: AppAction.setNicknameTextField
                            )
                        )
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        if !isNicknameValid {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.red)
                                .transition(.opacity.animation(.default))
                        }
                    }
                    Text("Lowercase letters, numbers, and dashes only")
                        .foregroundColor(
                            isNicknameValid ? Color.secondary : Color.red
                        )
                        .animation(.default, value: isNicknameValid)
                        .font(.caption)
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
