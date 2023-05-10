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

    var body: some View {
        let did = Did(app.state.sphereIdentity ?? "") ?? Config.default.subconsciousGeistDid
        NavigationStack {
            VStack(spacing: AppTheme.padding * 4) {
                Spacer()
                VStack(spacing: AppTheme.padding * 4) {
                    Text("Your sphere connects you to the Noosphere where you can discover, explore and follow other spheres.")
                        .foregroundColor(.secondary)
                    StackedGlowingImage(image: {
                        AnyView(
                            HStack(spacing: AppTheme.unit * 2) {
                                GenerativeProfilePic(
                                    did: did,
                                    size: 70
                                )
                                Line()
                                    .stroke(style: StrokeStyle(lineWidth: 3,  dash: [10, 3]))
                                    .frame(height: 1)
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .frame(width: 48)
                                Image("ns_logo")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                            }
                        )
                    }, width: 128, height: 64)
                }
                Spacer()
                Text("Ready?")
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
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
