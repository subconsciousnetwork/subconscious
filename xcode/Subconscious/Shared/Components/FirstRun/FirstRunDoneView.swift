//
//  FirstRunDoneView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//
import ObservableStore
import SwiftUI

struct FirstRunDoneView: View {
    @ObservedObject var app: Store<AppModel>
    @Environment(\.colorScheme) var colorScheme
    
    private var status: ResourceStatus {
        app.state.gatewayProvisioningStatus
    }
    
    private var dottedLine: some View {
        Line()
            .stroke(style: StrokeStyle(
                lineWidth: 3,
                dash: [6, 3]
            ))
            .frame(height: 1)
            .foregroundColor(.secondary.opacity(0.5))
            .frame(width: 24)
    }
    
    private var did: Did? {
        Did(app.state.sphereIdentity ?? "")
    }
    
    var statusLabel: String {
        switch (status) {
        case .pending:
            return "Creating your sphere..."
        case .succeeded:
            return "Connected!"
        case .initial:
            // Shown if the user skips the invite code step
            return "You are offline."
        case .failed:
            return "Failed to create sphere."
        }
    }
    
    var guidanceLabel: String {
        switch (status) {
        case .pending:
            return "You can start exploring the app offline."
        case .succeeded:
            return "Welcome to Subconscious."
            
        // Shown if the user skips the invite code step OR we fail to provision
        case .initial, .failed:
            return "Don't worry, you can still explore the app."
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.padding * 4) {
                Spacer()
                Text(statusLabel)
                .foregroundColor(.secondary)
                StackedGlowingImage(
                    width: 128,
                    height: 64
                ) {
                    HStack(
                        alignment: .center,
                        spacing: AppTheme.unit2
                    ) {
                        if let did = did {
                            GenerativeProfilePic(
                                did: did,
                                size: 64
                            )
                        }
                        dottedLine
                        ResourceSyncBadge(status: status)
                        dottedLine
                        Image("ns_logo")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .offset(x: -5) // account for padding in image
                    }
                    .frame(height: 64)
                }
                Text(guidanceLabel)
                    .foregroundColor(.secondary)
                Spacer()
                Button(
                    action: {
                        app.send(.persistFirstRunComplete(true))
                    }
                ) {
                    Text("Begin")
                }
                .buttonStyle(PillButtonStyle())
                .disabled(app.state.sphereIdentity == nil)
            }
            .padding()
            .background(
                AppTheme.onboarding
                    .appBackgroundGradient(colorScheme)
            )
        }
    }
}

struct FirstRunDoneView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunDoneView(
            app: Store(
                state: AppModel(
                    gatewayProvisioningStatus: .pending
                ),
                environment: AppEnvironment()
            )
        )
    }
}
