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
    
    private var bgGradient: LinearGradient {
        switch colorScheme {
        case .dark:
            return Color.bgGradientDark
        default:
            return Color.bgGradientLight
        }
    }

    private var shadow: Color {
        switch colorScheme {
        case .dark:
            return .brandBgPurple
        default:
            return .brandMarkPink
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(spacing: AppTheme.unit3) {
                    StackedGlowingImage(
                        image: Image("ns_logo"),
                        width: 180,
                        height: 180
                    )
                    Text("Welcome to the Noosphere!")
                        .foregroundColor(.secondary)
                }
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
            .background(bgGradient)
        }
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
