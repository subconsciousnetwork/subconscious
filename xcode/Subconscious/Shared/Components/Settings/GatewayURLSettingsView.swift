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
            Section(
                content: {
                    ValidatedFormField(
                        placeholder: "http://example.com",
                        field: app.state.gatewayURLField,
                        send: Address.forward(
                            send: app.send,
                            tag: AppAction.gatewayURLField
                        ),
                        caption: "The URL of your preferred Noosphere gateway"
                    )
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .onDisappear {
                        app.send(.submitGatewayURLForm)
                    }
                    .disabled(app.state.gatewayOperationInProgress)
                    
                    Button(
                        action: {
                            app.send(.submitGatewayURLForm)
                        },
                        label: {
                            GatewaySyncLabel(
                                status: app.state.lastGatewaySyncStatus
                            )
                        }
                    )
                    .disabled(
                        app.state.gatewayURL.count == 0 ||
                        app.state.gatewayOperationInProgress
                    )
                }, header: {
                    Text("Gateway URL")
                }, footer: {
                    switch app.state.lastGatewaySyncStatus {
                    case let .failed(message):
                        Text(message)
                    default:
                        EmptyView()
                    }
                }
            )
            
            if let gatewayId = app.state.gatewayId {
                GatewayProvisioningSettingsSection(app: app, gatewayId: gatewayId)
            }
            
            InviteCodeSettingsSection(app: app)
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
