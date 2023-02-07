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
            LabeledContent("foo", value: "bar")
            TextField(
                "nickname", text: Binding(
                    get: { app.state.nicknameTextField },
                    send: app.send,
                    tag: AppAction.setNicknameTextField
                )
            )
        }
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
