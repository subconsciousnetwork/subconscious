//
//  FirstRunView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/19/23.
//
import ObservableStore
import SwiftUI

struct FirstRunView: View {
    @ObservedObject var app: Store<AppModel>
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack(
            path: Binding(
                get: { app.state.firstRunPath },
                send: app.send,
                tag: AppAction.setFirstRunPath
            )
        ) {
            VStack(spacing: AppTheme.padding) {
                Spacer()
                StackedGlowingImage() {
                    Image("sub_logo").resizable()
                }
                .aspectRatio(contentMode: .fit)
                .frame(
                    minWidth: 32,
                    maxWidth: AppTheme.onboarding.heroIconSize,
                    minHeight: 32,
                    maxHeight: AppTheme.onboarding.heroIconSize
                )
                
                Spacer()
                
                Text("Subconscious is a place to garden thoughts and share them with others.")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    
                Text("It’s powered by Noosphere, a decentralized protocol, so your data belongs to you.")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                if let gatewayId = app.state.gatewayId {
                    VStack(spacing: AppTheme.unit2) {
                        HStack(spacing: AppTheme.unit2) {
                            Text("Invite code redeemed")
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .opacity(0.5)
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
                } else {
                    ValidatedFormField(
                        alignment: .center,
                        placeholder: "Enter your invite code",
                        field: app.state.inviteCodeFormField,
                        send: Address.forward(
                            send: app.send,
                            tag: AppAction.inviteCodeFormField
                        ),
                        caption: Func.run {
                            switch app.state.inviteCodeRedemptionStatus {
                            case .failed(_):
                                return "Failed to redeem invite code"
                            case _:
                                return "Your ticket to the Noosphere"
                            }
                        },
                        onFocusChanged: { focused in
                            // User finished editing the field
                            if !focused {
                                app.send(.submitInviteCodeForm)
                            }
                        },
                        isValid: Func.run {
                            switch app.state.inviteCodeRedemptionStatus {
                            case .failed(_):
                                return false
                            case _:
                                return true
                            }
                        }
                    )
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                }
                
                if !app.state.inviteCodeFormField.hasFocus {
                    Spacer()
                    
                    NavigationLink(
                        value: FirstRunStep.nickname,
                        label: {
                            Text("Get Started")
                        }
                    )
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
                            
                            NavigationLink(
                                value: FirstRunStep.nickname,
                                label: {
                                    Text("Use offline")
                                        .font(.caption)
                                }
                            )
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
            .navigationTitle("Welcome to Subconscious")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .background(
                AppTheme.onboarding
                    .appBackgroundGradient(colorScheme)
            )
            .navigationDestination(
                for: FirstRunStep.self
            ) { step in
                switch step {
                case .nickname:
                    FirstRunProfileView(app: app)
                case .sphere:
                    FirstRunSphereView(app: app)
                case .recovery:
                    FirstRunRecoveryView(app: app)
                case .connect:
                    FirstRunDoneView(app: app)
                }
            }
            .onAppear {
                guard app.state.sphereIdentity == nil else {
                    return
                }
                
                app.send(.createSphere)
            }
        }
    }
}

struct FirstRunView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
