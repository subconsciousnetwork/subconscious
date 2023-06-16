//
//  GatewayURLSettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore

struct PendingSyncBadge: View {
    @State var spin = false
    
    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(Animation.linear
                .repeatForever(autoreverses: false)
                .speed(0.4), value: spin)
            .task{
                self.spin = true
            }
    }
}

struct ResourceSyncBadge: View {
    var status: ResourceStatus

    var body: some View {
        switch status {
        case .initial:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.secondary)
        case .pending:
            PendingSyncBadge()
                .foregroundColor(.secondary)
        case .succeeded:
            Image(systemName: "checkmark.circle")
                .foregroundColor(.secondary)
        case .failed:
            Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                .foregroundColor(.red)
        }
    }
}


struct GatewayProvisionLabel: View {
    var status: ResourceStatus
    var inviteCode: InviteCode?
    var gatewayId: String?
    
    var label: String {
        switch (status, inviteCode, gatewayId) {
        case (.initial, .some(_), .some):
            return "Check Gateway Status"
        case (.pending, .some, .none):
            return "Redeeming Invite Code..."
        case (.pending, .some, .some):
            return "Waiting..."
        case (.failed, _, .none):
            return "Failed to Redeem Invite Code"
        case (.failed, _, .some):
            return "Provisioning Failed"
        case (.succeeded, _, _):
            return "Gateway Ready"
        case _:
            return "Provision Gateway"
        }
    }
    
    var color: Color {
        switch status {
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }

    var body: some View {
        Label(title: {
            Text(label)
        }, icon: {
            ResourceSyncBadge(status: status)
        })
        .foregroundColor(color)
    }
}

struct GatewayURLSettingsView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        Form {
            Section(
                content: {
                    ValidatedFormField(
                        placeholder: "http://example.com",
                        field: app.state.gatewayURLField,
                        send: app.send,
                        tag: AppAction.gatewayURLField,
                        caption: "The URL of your preferred Noosphere gateway"
                    )
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .onDisappear {
                        guard let url = app.state.gatewayURLField.validated else {
                            return
                        }
                        
                        app.send(.submitGatewayURL(url))
                    }
                    
                    if app.state.gatewayProvisioningStatus != .pending {
                        Button(
                            action: {
                                app.send(.syncSphereWithGateway)
                            },
                            label: {
                                GatewaySyncLabel(
                                    status: app.state.lastGatewaySyncStatus
                                )
                            }
                        )
                        .disabled(app.state.gatewayURL.count == 0)
                    }
                }, header: {
                    Text("Gateway")
                }, footer: {
                    switch app.state.lastGatewaySyncStatus {
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
