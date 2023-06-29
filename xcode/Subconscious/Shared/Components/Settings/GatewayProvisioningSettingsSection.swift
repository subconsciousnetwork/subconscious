//
//  GatewayProvisioningSettingsSection.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/6/2023.
//

import Foundation
import SwiftUI
import ObservableStore

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

struct GatewayProvisioningSettingsSection: View {
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
                        app.send(.requestGatewayProvisioningStatus)
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
                Text("Your Gateway")
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
