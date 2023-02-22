//
//  GatewayURLSettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore

struct GatewayURLSettingsView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        Form {
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
            .autocapitalization(.none)
            .autocorrectionDisabled(true)
            .keyboardType(.URL)
            .onDisappear {
                app.send(.submitGatewayURL(app.state.gatewayURLTextField))
            }
        }
        .navigationTitle("Gateway URL")
    }
}

struct GatewaySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GatewayURLSettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
