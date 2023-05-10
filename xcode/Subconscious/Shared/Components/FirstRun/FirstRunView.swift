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
        NavigationStack {
            VStack(spacing: AppTheme.padding * 2) {
                Spacer()
                StackedGlowingImage(
                    width: AppTheme.onboarding.heroIconSize,
                    height: AppTheme.onboarding.heroIconSize
                ) {
                    Image("sub_logo").resizable()
                }
                Spacer()
                VStack(alignment: .leading, spacing: AppTheme.unit3) {
                    Text("Subconscious is a place to garden thoughts and share them with others.")
                    
                    Text("It’s powered by Noosphere, a decentralized protocol, so your data belongs to you.")
                }
                .foregroundColor(.secondary)
                .font(.callout)
                
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
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                
                Spacer()
                
                NavigationLink(
                    destination: {
                        FirstRunProfileView(
                            app: app
                        )
                    },
                    label: {
                        Text("Get Started")
                    }
                )
                .buttonStyle(PillButtonStyle())
                .disabled(!app.state.inviteCodeFormField.isValid)
                .simultaneousGesture(TapGesture().onEnded {
                    app.send(.createSphere)
                })
                    
                // MARK: Use Offline
                VStack(spacing: AppTheme.unit) {
                    Text("No invite code?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    NavigationLink(
                        destination: {
                            FirstRunProfileView(
                                app: app
                            )
                        },
                        label: {
                            
                            Text("Use offline")
                                .font(.caption)
                        }
                    )
                    .simultaneousGesture(TapGesture().onEnded {
                        app.send(.createSphere)
                    })
                }
            }
            .navigationTitle("Welcome to Subconscious")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .background(
                AppTheme.onboarding
                    .appBackgroundGradient(colorScheme)
            )
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
