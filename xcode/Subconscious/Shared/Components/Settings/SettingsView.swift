//
//  SettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/3/23.
//

import SwiftUI
import ObservableStore

struct GatewaySyncLabel: View {
    var status: ResourceStatus
    
    private var label: String {
        switch status {
        case .initial:
            return "Sync with Gateway"
        case .pending:
            return "Syncing..."
        case .failed:
            return "Sync Failed"
        case .succeeded:
            return "Sync Complete"
        }
    }
    
    private var color: Color {
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

struct GatewayProvisioningSection: View {
    @ObservedObject var app: Store<AppModel>
    
    var body: some View {
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
}

// MARK: Sync

struct GatewaySyncSection: View {
    @ObservedObject var app: Store<AppModel>
    
    var body: some View {
        Section(
            content: {
                NavigationLink(
                    destination: {
                        GatewayURLSettingsView(app: app)
                    },
                    label: {
                        LabeledContent(
                            "Gateway",
                            value: app.state.gatewayURL
                        )
                        .lineLimit(1)
                    }
                )
                
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
}

// MARK: Settings

struct SettingsView: View {
    @ObservedObject var app: Store<AppModel>
    var unknown = "Unknown"
    
    var body: some View {
        NavigationStack {
            Form {
                if app.state.isNoosphereEnabled {
                    Section(header: Text("Noosphere")) {
                        NavigationLink(
                            destination: {
                                ProfileSettingsView(app: app)
                            },
                            label: {
                                LabeledContent(
                                    "Nickname",
                                    value: app.state.nickname
                                )
                                .lineLimit(1)
                                .textSelection(.enabled)
                            }
                        )
                        
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
                        .lineLimit(1)
                        .textSelection(.enabled)
                    }
                    if app.state.gatewayProvisioningStatus == .succeeded {
                        GatewaySyncSection(app: app)
                    } else {
                        GatewayProvisioningSection(app: app)
                    }
                }
                Section {
                    NavigationLink("Developer Settings") {
                        DeveloperSettingsView(app: app)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        app.send(.presentSettingsSheet(false))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                app.send(.refreshSphereVersion)
            }
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
