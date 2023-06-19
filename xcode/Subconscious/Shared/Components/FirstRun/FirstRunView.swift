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
                
                ValidatedFormField(
                    alignment: .center,
                    placeholder: "Enter your invite code",
                    field: app.state.inviteCodeFormField,
                    send: Address.forward(
                        send: app.send,
                        tag: AppAction.inviteCodeFormField
                    ),
                    caption: "Look for this in your welcome email.",
                    submitLabel: .go,
                    onSubmit: {
                        if app.state.inviteCodeFormField.isValid {
                            app.send(.pushFirstRunStep(.nickname))
                        }
                    }
                )
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                
                
                if !app.state.inviteCodeFormField.hasFocus {
                    Spacer()
                    
                    NavigationLink(
                        value: FirstRunStep.nickname,
                        label: {
                            Text("Get Started")
                        }
                    )
                    .buttonStyle(PillButtonStyle())
                    .disabled(!app.state.inviteCodeFormField.isValid)
                }
                
                // MARK: Use Offline
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
                .padding(
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
