//
//  AppUpgradeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/22/23.
//

import SwiftUI
import Combine
import ObservableStore

/// Displays information to the user when app migration / rebuild happening.
struct AppUpgradeView: View {
    private var shadow: Color {
        switch colorScheme {
        case .dark:
            return .brandBgPurple
        default:
            return .brandMarkPurple
        }
    }

    private let spinnerSize: CGFloat = 256
    private let logoSize: CGFloat = AppTheme.onboarding.heroIconSize
    // Duration of certain completion transition animations
    private let transitionDuration: CGFloat = 1

    @Environment(\.colorScheme) var colorScheme
    var state: AppUpgradeModel
    var send: (AppUpgradeAction) -> Void

    var body: some View {
        VStack {
            VStack {
                if state.isComplete {
                    Text("Welcome to Subconscious").transition(
                        .asymmetric(
                            insertion: .opacity.animation(
                                .easeOut(duration: transitionDuration)
                                .delay(transitionDuration)
                            ),
                            removal: .opacity.animation(.default)
                        )
                    )
                } else {
                    Text("What? Subconscious is evolving!").transition(
                        .opacity.animation(
                            .easeOut(duration: transitionDuration)
                        )
                    )
                }
            }
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .font(.body)
            .bold()
            
            Spacer()

            VStack(alignment: .center) {
                ProgressTorusView(
                    isComplete: state.isComplete,
                    size: spinnerSize
                ) {
                    StackedGlowingImage() {
                        Image("sub_logo").resizable()
                    }
                    .animation(.none, value: colorScheme)
                    .frame(
                        width: logoSize,
                        height: logoSize
                    )
                }
                Spacer().frame(height: AppTheme.unit * 12)
                if !state.isComplete {
                    Text(verbatim: state.progressMessage)
                        .id(state.progressMessage)
                        .transition(.push(from: .bottom))
                }
            }
            .italic()
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: spinnerSize)

            Spacer()

            VStack(alignment: .center, spacing: AppTheme.unit) {
                Text("Upgrading your Subconscious.")
                Text("This might take a minute.")
            }
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: spinnerSize)
            .opacity(state.isComplete ? 0 : 1)
            .animation(.default, value: state.isComplete)

            Spacer()

            Button("Continue", action: {
                send(.continue)
            })
            .buttonStyle(PillButtonStyle())
            .disabled(!state.isComplete)
        }
        .padding(EdgeInsets(
            top: AppTheme.unit2,
            leading: AppTheme.padding,
            bottom: AppTheme.padding,
            trailing: AppTheme.padding
        ))
        .frame(maxWidth: .infinity)
        .background(
            AppTheme.onboarding
                .appBackgroundGradient(colorScheme)
        )
    }
}

enum AppUpgradeAction: Hashable {
    case setProgressMessage(_ message: String)
    case setComplete(_ isComplete: Bool)
    case `continue`
}

struct AppUpgradeModel: ModelProtocol {
    typealias Action = AppUpgradeAction
    typealias Environment = Void

    var progressMessage: String = String(localized: "Upgrading...")
    var isComplete = false
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .setProgressMessage(let message):
            var model = state
            model.progressMessage = message
            return Update(state: model).animation(.default)
        case .setComplete(let isComplete):
            var model = state
            model.isComplete = isComplete
            return Update(state: model).animation(.default)
        case .continue:
            return Update(state: state)
        }
    }
}

struct AppUpgradeView_Previews: PreviewProvider {
    struct TestView: View {
        private let timer = Timer
            .publish(every: 5, on: .main, in: .common)
            .autoconnect()

        @StateObject private var store = Store(
            state: AppUpgradeModel(),
            environment: ()
        )

        var body: some View {
            AppUpgradeView(state: store.state, send: store.send)
                .onReceive(timer) { time in
                    store.send(.setComplete(!store.state.isComplete))
                }
        }
    }

    static var previews: some View {
        TestView()
        AppUpgradeView(
            state: AppUpgradeModel(
                progressMessage: "Transferring notes to database...",
                isComplete: false
            ),
            send: { action in }
        )
        AppUpgradeView(
            state: AppUpgradeModel(
                progressMessage: "Transferring notes to database...",
                isComplete: true
            ),
            send: { action in }
        )
    }
}
