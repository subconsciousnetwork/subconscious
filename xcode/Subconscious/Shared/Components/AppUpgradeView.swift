//
//  AppUpgradeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/22/23.
//

import SwiftUI
import ObservableStore

/// Displays information to the user when app migration / rebuild happening.
struct AppUpgradeView: View {
    var state: AppUpgradeModel
    var send: (AppUpgradeAction) -> Void

    var body: some View {
        VStack {
            Text("What? Subconscious is evolving!")
                .font(.title2)
            Spacer()
            
            ProgressView()
            Spacer()
            VStack(alignment: .leading, spacing: AppTheme.unit) {
                ForEach(state.events) { event in
                    switch event.value {
                    case .success(let message):
                        Label(
                            title: {
                                Text(verbatim: message)
                            },
                            icon: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        )
                        .transition(.push(from: .bottom))
                    case .failure(let message):
                        Label(
                            title: {
                                Text(verbatim: message)
                            },
                            icon: {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        )
                        .transition(.push(from: .bottom))
                    }
                }

            }
            .multilineTextAlignment(.center)
            .font(.body)
            .foregroundColor(.secondary)

            Spacer()

            Button("Continue", action: {})
                .buttonStyle(LargeButtonStyle())
                .disabled(!state.isComplete)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white)
    }
}

enum AppUpgradeAction: Hashable {
    case event(_ event: AppUpgradeEvent)
    case setComplete(_ isComplete: Bool)
    case addEventAndSetComplete(event: AppUpgradeEvent, isComplete: Bool)
    case `continue`
}

/// Represents an event during the sync process
enum AppUpgradeEvent: Hashable {
    case success(_ message: String)
    case failure(_ message: String)
}

struct AppUpgradeModel: ModelProtocol {
    typealias Action = AppUpgradeAction
    typealias Environment = Void

    var events: [Identified<AppUpgradeEvent>] = []
    var isComplete = false
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .event(let event):
            var model = state
            model.events.append(
                Identified(value: event)
            )
            return Update(state: model).animation(.default)
        case .setComplete(let isComplete):
            var model = state
            model.isComplete = isComplete
            return Update(state: model).animation(.default)
        case .continue:
            return Update(state: state)
        case let .addEventAndSetComplete(event, isComplete):
            return update(
                state: state,
                actions: [
                    .event(event),
                    .setComplete(isComplete)
                ],
                environment: ()
            ).animation(.default)
        }
    }
}

struct AppUpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        AppUpgradeView(
            state: AppUpgradeModel(
                events: [
                    Identified(value: .success("Database upgraded")),
                    Identified(value: .success("Local files synced")),
                    Identified(value: .failure("Sphere files didn't sync")),
                ]
            ),
            send: { action in }
        )
    }
}
