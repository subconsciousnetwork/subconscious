//
//  InviteCodeSettingsSection.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/6/2023.
//

import Foundation
import SwiftUI
import ObservableStore

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
        Label(
            title: {
                Text(label)
            },
            icon: {
                ResourceSyncBadge(status: status)
            }
        )
        .foregroundColor(color)
    }
}

struct ValidatedInviteCodeFormField: View {
    @ObservedObject var app: Store<AppModel>
    
    var caption: String {
        switch app.state.inviteCodeRedemptionStatus {
        case .failed(_):
            return String(localized: "Could not redeem invite code")
        case _:
            return String(localized: "You can find your invite code in your welcome email")
        }
    }
    
    var body: some View {
        ValidatedFormField(
            placeholder: "Enter an invite code",
            field: app.state.inviteCodeFormField,
            send: Address.forward(
                send: app.send,
                tag: AppAction.inviteCodeFormField
            ),
            caption: caption
        )
        .autocapitalization(.none)
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
        .disabled(app.state.gatewayOperationInProgress)
    }
}

struct InviteCodeSettingsSection: View {
    @ObservedObject var app: Store<AppModel>
    
    var body: some View {
        Section(
            content: {
                ValidatedInviteCodeFormField(app: app)
                
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
