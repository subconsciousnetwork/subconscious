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
                hasError: !app.state.isGatewayURLTextFieldValid
            )
            .formField()
            .autocapitalization(.none)
            .autocorrectionDisabled(true)
            .keyboardType(.URL)
            .onDisappear {
                app.send(.submitGatewayURL(app.state.gatewayURLTextField))
            }
            
            Section(
                content: {
                    ValidatedTextField(
                        placeholder: "Enter your invite code",
                        text: Binding(
                            get: { app.state.inviteCodeFormField.value },
                            send: app.send,
                            tag: AppAction.setInviteCode
                        ),
                        caption: "Look for this in your welcome email.",
                        hasError: app.state.inviteCodeFormField.hasError
                    )
                    .formField()
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .onDisappear {
                        app.send(.setInviteCode(app.state.inviteCodeFormField.value))
                    }
                    
                    Button(
                        action: {
                            app.send(.provisionGateway)
                        },
                        label: {
                            Label(
                                title: {
                                    Text("Provision Gateway")
                                },
                                icon: {
                                    Image(systemName: "icloud.and.arrow.up")
                                }
                            )
                        }
                    )
                    .disabled(
                        !app.state.inviteCodeFormField.isValid
                        || app.state.lastGatewaySyncStatus == .pending
                    )
                },
                header: {
                    Text("Provision Gateway")
                },
                footer: {
                    switch (app.state.gatewayProvisioningStatus) {
                    case let .failed(message):
                        Text(message)
                    default:
                        EmptyView()
                    }
                }
            )
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
