//
//  FirstRunDoneView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//
import ObservableStore
import SwiftUI

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

struct FirstRunDoneView: View {
    @ObservedObject var app: Store<AppModel>
    @Environment(\.colorScheme) var colorScheme
    
    var status: ResourceStatus {
        app.state.gatewayProvisioningStatus
    }

    var body: some View {
        let did = Did(app.state.sphereIdentity ?? "") ?? Config.default.subconsciousGeistDid
        NavigationStack {
            VStack(spacing: AppTheme.padding * 4) {
                Spacer()
                VStack(spacing: AppTheme.padding * 2) {
                Text(status == .succeeded ? "Connected!" : "Connecting to Noosphere...")
                        .foregroundColor(.secondary)
                    StackedGlowingImage(image: {
                        AnyView(
                            HStack(alignment: .center, spacing: AppTheme.unit2) {
                                GenerativeProfilePic(
                                    did: did,
                                    size: 64
                                )
                                Line()
                                    .stroke(style: StrokeStyle(lineWidth: 3,  dash: [6, 3]))
                                    .frame(height: 1)
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .frame(width: 24)
                                GatewayProvisionBadge(status: status)
                                Line()
                                    .stroke(style: StrokeStyle(lineWidth: 3,  dash: [5, 3]))
                                    .frame(height: 1)
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .frame(width: 24)
                                Image("ns_logo")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .offset(x: -5)
                            }
                        )
                    }, width: 128, height: 64)
                }
                Text(status == .succeeded ? "Welcome to Subconscious." : "You can start exploring the app offline.")
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
                state: AppModel(gatewayProvisioningStatus: .pending),
                environment: AppEnvironment()
            )
        )
    }
}
