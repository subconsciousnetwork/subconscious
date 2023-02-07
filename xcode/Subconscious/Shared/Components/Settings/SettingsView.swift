//
//  SettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/3/23.
//

import SwiftUI
import ObservableStore

struct SettingsView: View {
    @ObservedObject var app: Store<AppModel>
    var unknown = "Unknown"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Noosphere")) {
                    Toggle(
                        "Enable Noosphere",
                        isOn: Binding(
                            get: { app.state.isNoosphereEnabled },
                            send: app.send,
                            tag: AppAction.setNoosphereEnabled
                        )
                    )
                }

                Section(header: Text("Sphere")) {
                    LabeledContent("Nickname", value: app.state.nickname ?? "")
                        .textSelection(.enabled)
                    LabeledContent(
                        "Sphere",
                        value: app.state.sphereIdentity ?? unknown
                    )
                    .lineLimit(1)
                    .textSelection(.enabled)
                    LabeledContent(
                        "Version",
                        value: app.state.sphereVersion ?? unknown
                    )
                    .textSelection(.enabled)
                }
                
                Section(header: Text("Gateway")) {
                    LabeledContent(
                        "Gateway URL",
                        value: app.state.gatewayURL
                    )
                    .textSelection(.enabled)
                    NavigationLink("Gateway Settings") {
                        GatewaySettingsView(app: app)
                    }
                }

                Section(header: Text("Developer")) {
                    NavigationLink("Developer Settings") {
                        DeveloperSettingsView(app: app)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
