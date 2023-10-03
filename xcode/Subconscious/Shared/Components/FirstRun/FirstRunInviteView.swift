//
//  FirstRunInviteView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/10/2023.
//

import ObservableStore
import SwiftUI

struct InviteCodeRedeemedView: View {
    var gatewayId: String
    
    var body: some View {
        VStack(spacing: AppTheme.unit2) {
            HStack(spacing: AppTheme.unit2) {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .opacity(0.5)
                Text("Invitation accepted")
            }
            .font(.body)
            .bold()
            
            HStack(spacing: AppTheme.unit) {
                Text("Gateway ID")
                    .bold()
                Text(gatewayId)
            }
            .font(.caption)
        }
        .foregroundColor(.secondary)
    }
}

struct FirstRunInviteView: View {
    @ObservedObject var app: Store<AppModel>
    @Environment(\.colorScheme) var colorScheme
    
    var inviteCodeCaption: String {
        switch app.state.inviteCodeRedemptionStatus {
        case .failed(_):
            return String(localized: "Could not redeem invite code")
        case _:
            return String(localized: "You can find your invite code in your welcome email")
        }
    }
    
    var body: some View {
        VStack(spacing: AppTheme.padding) {
            Spacer()
            
            if !app.state.inviteCodeFormField.hasFocus {
                StackedGlowingImage() {
                    Image("ns_logo").resizable()
                }
                .aspectRatio(contentMode: .fit)
                .frame(
                    minWidth: 32,
                    maxWidth: AppTheme.onboarding.heroIconSize,
                    minHeight: 32,
                    maxHeight: AppTheme.onboarding.heroIconSize
                )
            }
            
            Spacer()
            
            Text("Subconscious is powered by Noosphere, a decentralized protocol, so your data is accessible anywhere and belongs to you.")
                .foregroundColor(.secondary)
                .font(.callout)
                .multilineTextAlignment(.center)
            
            Text("Enter your invite code to create your Noosphere gateway:")
                .foregroundColor(.secondary)
                .font(.callout)
                .multilineTextAlignment(.center)
            
            if let gatewayId = app.state.gatewayId {
                InviteCodeRedeemedView(
                    gatewayId: gatewayId
                )
            } else {
                ValidatedFormField(
                    alignment: .center,
                    placeholder: "Enter your invite code",
                    field: app.state.inviteCodeFormField,
                    send: Address.forward(
                        send: app.send,
                        tag: AppAction.inviteCodeFormField
                    ),
                    caption: inviteCodeCaption,
                    onFocusChanged: { focused in
                        // User finished editing the field
                        if !focused {
                            app.send(.submitInviteCodeForm)
                        }
                    }
                )
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .disabled(app.state.gatewayOperationInProgress)
            }
            
            if !app.state.inviteCodeFormField.hasFocus {
                Spacer()
                
                Button(action: {
                    app.send(.submitFirstRunInviteStep)
                }, label: {
                    Text("Continue")
                })
                .buttonStyle(PillButtonStyle())
                .disabled(app.state.gatewayId == nil)
            }
            
            // MARK: Use Offline
            VStack {
                if app.state.gatewayId == .none {
                    HStack(spacing: AppTheme.unit) {
                        Text("No invite code?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            app.send(.requestOfflineMode)
                        }, label: {
                            Text("Use offline")
                                .font(.caption)
                        })
                    }
                }
            }.padding(
                .init(
                    top: 0,
                    leading: 0,
                    bottom: AppTheme.tightPadding,
                    trailing: 0
                )
            )
        }
        .navigationTitle("Invite Code")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
        .background(
            AppTheme.onboarding
                .appBackgroundGradient(colorScheme)
        )
    }
}

struct FirstRunInviteView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunInviteView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
