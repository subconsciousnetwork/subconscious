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
                .padding(AppTheme.padding)
                
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
                
                Button(action: {
                    app.send(.submitFirstRunWelcomeStep)
                }, label: {
                    Text("Get Started")
                })
                .buttonStyle(PillButtonStyle())
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
                case .profile:
                    FirstRunProfileView(app: app)
                case .sphere:
                    FirstRunSphereView(app: app)
                case .recovery:
                    FirstRunRecoveryView(app: app)
                case .invite:
                    FirstRunInviteView(app: app)
                case .done:
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
