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

struct RedeemInviteCodeLabel: View {
    var status: ResourceStatus
    
    var label: String {
        switch (status) {
        case .initial:
            return "Redeem Invite Code"
        case .pending:
            return "Redeeming..."
        case .failed:
            return "Failed to Redeem Invite Code"
        case .succeeded:
            return "Code Redeemed"
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


struct GatewayProvisionLabel: View {
    var status: ResourceStatus
    
    var label: String {
        switch (status) {
        case .initial:
            return "Check Gateway Status"
        case .pending:
            return "Waiting..."
        case .failed:
            return "Gateway Error"
        case .succeeded:
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

// MARK: Provisioning

struct InviteCodeSection: View {
    @ObservedObject var app: Store<AppModel>
    
    var body: some View {
        Section(
            content: {
                ValidatedFormField(
                    placeholder: "Enter an invite code",
                    field: app.state.inviteCodeFormField,
                    send: Address.forward(
                        send: app.send,
                        tag: AppAction.inviteCodeFormField
                    ),
                    caption: "Your ticket to the Noosphere"
                )
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
                .disabled(app.state.gatewayOperationInProgress)
                
                Button(
                    action: {
                        app.send(.submitInviteCodeForm)
                    },
                    label: {
                        RedeemInviteCodeLabel(
                            status: app.state.inviteCodeRedemptionStatus
                        )
                    }
                )
                .disabled(
                    !app.state.inviteCodeFormField.isValid ||
                    app.state.gatewayOperationInProgress
                )
            },
            header: {
                Text("Invite Code")
            },
            footer: {
                VStack {
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
}

struct GatewayProvisioningSection: View {
    @ObservedObject var app: Store<AppModel>
    var gatewayId: String
    
    var body: some View {
        Section(
            content: {
                LabeledContent(
                    "Gateway ID",
                    value: gatewayId
                )
                .lineLimit(1)
                .textSelection(.enabled)
                
                if let inviteCode = app.state.inviteCode {
                    LabeledContent(
                        "Invite Code",
                        value: inviteCode.description
                    )
                    .lineLimit(1)
                    .textSelection(.enabled)
                }
                
                Button(
                    action: {
                        app.send(.submitProvisionGatewayForm)
                    },
                    label: {
                        GatewayProvisionLabel(
                            status: app.state.gatewayProvisioningStatus
                        )
                    }
                )
                .disabled(app.state.gatewayOperationInProgress)
            },
            header: {
                Text("Provision Gateway")
            },
            footer: {
                VStack {
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
                GatewayProvisioningSection(app: app, gatewayId: gatewayId)
            }
            InviteCodeSection(app: app)
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
