//
//  GatewaySettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore

struct GatewaySettingsView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        Form {
            Section(header: Text("Gateway URL")) {
                ValidatedTextField(
                    placeholder: "http://example.com",
                    text: Binding(
                        get: { app.state.gatewayURLTextField },
                        send: app.send,
                        tag: AppAction.setGatewayURLTextField
                    ),
                    caption: "The URL of your preferred Noosphere gateway",
                    isValid: app.state.isGatewayURLTextFieldValid
                )
                .onDisappear {
                    app.send(.submitGatewayURL(app.state.gatewayURLTextField))
                }
            }
            Section {
                Button(
                    action: {
                        app.send(.syncSphereWithGateway)
                    },
                    label: {
                        Text("Sync with Gateway")
                    }
                )
            }
        }
        .navigationTitle("Gateway")
    }
}

struct GatewaySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GatewaySettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
