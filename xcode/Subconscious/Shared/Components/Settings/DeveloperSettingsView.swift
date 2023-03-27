//
//  GatewaySettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore

struct DeveloperSettingsView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        Form {
            Section(footer: Text("**Beta**: Noosphere is an open and decentralized protocol for sharing notes. This feature is in development. Enable at your own risk.")) {
                Toggle(
                    "Enable Noosphere",
                    isOn: Binding(
                        get: { app.state.isNoosphereEnabled },
                        send: app.send,
                        tag: AppAction.persistNoosphereEnabled
                    )
                )
            }
            Button(
                action: {
                    app.send(.persistFirstRunComplete(false))
                },
                label: {
                    Text("Reset First Run Experience")
                }
            )
        }
        .navigationTitle("Developer")
    }
}

struct DeveloperSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperSettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
