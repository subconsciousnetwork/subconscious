//
//  GatewayURLSettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore

struct GatewayProvisionBadge: View {
    var status: ResourceStatus
    @State var spin = false
    
    private func labelColor(status: ResourceStatus) -> Color {
        switch status {
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }

    var body: some View {
                switch status {
                case .initial:
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(.secondary)
                case .pending:
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.accentColor)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(Animation.linear
                            .repeatForever(autoreverses: false)
                            .speed(0.4), value: spin)
                        .onAppear() {
                            // Avoids unwanted animation of position after layout
                            DispatchQueue.main.asyncAfter(deadline: .now()) {
                                self.spin = true
                            }
                        }
                case .succeeded:
                    Image(systemName: "checkmark.icloud")
                        .foregroundColor(.secondary)
                case .failed:
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundColor(.red)
                }
        }
}


struct GatewayProvisionLabel: View {
    var status: ResourceStatus
    @State var spin = false
    
    func label(status: ResourceStatus) -> String {
        switch status {
        case .initial:
            return "Provision Gateway"
        case .pending:
            return "Provisioning..."
        case .failed:
            return "Provisioning Failed"
        case .succeeded:
            return "Gateway Created"
        }
    }
    
    private func labelColor(status: ResourceStatus) -> Color {
        switch status {
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Label(title: {
                Text(label(status: status))
                    .foregroundColor(labelColor(status: status))
            }, icon: {
                GatewayProvisionBadge(status: status)
            })
        }
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
                    
                    Button(
                        action: {
                            app.send(.requestProvisionGateway)
                        },
                        label: {
                            GatewayProvisionLabel(
                                status: app.state.gatewayProvisioningStatus
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
                    switch app.state.gatewayProvisioningStatus {
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
