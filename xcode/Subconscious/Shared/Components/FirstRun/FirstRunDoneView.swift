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
    
    private var did: Did {
        Did(app.state.sphereIdentity ?? "")
            ?? Config.default.subconsciousGeistDid
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.padding * 4) {
                Spacer()
                VStack(spacing: AppTheme.padding * 2) {
                    Text(
                        status == .succeeded
                        ? "Connected!"
                        : "Connecting to Noosphere..."
                    )
                    .foregroundColor(.secondary)
                    StackedGlowingImage(
                        width: 128,
                        height: 64
                    ) {
                        HStack(
                            alignment: .center,
                            spacing: AppTheme.unit2
                        ) {
                            GenerativeProfilePic(
                                did: did,
                                size: 64
                            )
                            dottedLine
                            GatewayProvisionBadge(status: status)
                            dottedLine
                            Image("ns_logo")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .offset(x: -5) // account for padding in image
                        }
                    }
                }
                Text(
                    status == .succeeded
                    ? "Welcome to Subconscious."
                    : "You can start exploring the app offline."
                )
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

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
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
