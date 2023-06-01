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
                    .disabled(app.state.gatewayProvisioningStatus == .pending)
                    
                    Button(
                        action: {
                            app.send(.submitProvisionGatewayForm)
                        },
                        label: {
                            GatewayProvisionLabel(
                                status: app.state.gatewayProvisioningStatus,
                                inviteCode: app.state.inviteCodeFormField.validated,
                                gatewayId: app.state.gatewayId
                            )
                        }
                    )
                    .disabled(
                        !app.state.inviteCodeFormField.isValid ||
                        app.state.gatewayProvisioningStatus == .pending
                    )
                },
                header: {
                    Text("Provision Gateway")
                },
                footer: {
                    VStack {
                        if let gatewayId = app.state.gatewayId {
                            VStack(alignment: .leading) {
                                Text("Gateway ID")
                                    .foregroundColor(.secondary)
                                    .bold()
                                Text(gatewayId)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        switch app.state.gatewayProvisioningStatus {
                        case let .failed(message):
                            Text(message)
                        default:
                            EmptyView()
                        }
                            
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
