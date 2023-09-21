//
//  RecoveryView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 13/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore
import Combine
import os

struct AttemptRecoveryLabel: View {
    var status: ResourceStatus
    
    var label: String {
        switch (status) {
        case .initial:
            return "Attempt Recovery"
        case .pending:
            return "Recovering..."
        case .failed:
            return "Recovery Failed"
        case .succeeded:
            return "Recovery Complete"
        }
    }
    
    var color: Color {
        switch status {
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }

    var body: some View {
        Label(title: {
            Text(label)
        }, icon: {
            ResourceSyncBadge(status: status)
        })
        .foregroundColor(color)
    }
}

enum RecoveryViewTab {
    case explain
    case form
}

struct RecoveryView: View {
    @ObservedObject var app: Store<AppModel>
    @State var selectedTab = RecoveryViewTab.explain // TODO: move to a small, local store
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: AppTheme.padding) {
                Text("Recovery Mode")
                    .bold()
                    .padding(.bottom)
                
                Spacer()
                
                Image(systemName: "stethoscope")
                    .resizable()
                    .frame(width: 96, height: 96)
                    .foregroundColor(.secondary)
                
                Text(
                    "If you ever lose your device or experience data loss,"
                     + " you can recover your data using your recovery phrase and your gateway."
                )
                .multilineTextAlignment(.center)
                
                Text(
                    "We'll attempt to download and restore from the remote copy of your notes."
                )
                .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(
                    action: {
                        withAnimation {
                            selectedTab = .form
                        }
                    },
                    label: {
                        Text("Proceed")
                    }
                )
                .buttonStyle(PillButtonStyle())
                
                Button(
                    action: {
                        app.send(.presentRecoveryMode(false))
                    },
                    label: {
                        Text("Cancel")
                    }
                )
                
                Spacer()
            }
            .padding(AppTheme.padding)
            .tabItem {
                Text("Recovery")
            }
            .tag(RecoveryViewTab.explain)
            
            Form {
                Section(
                    content: {
                        ValidatedFormField(
                            placeholder: "did:key:abc",
                            field: app.state.recoveryDidField,
                            send: Address.forward(
                                send: app.send,
                                tag: AppAction.recoveryDidField
                            ),
                            caption: "The identity of your sphere"
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        
                        ValidatedFormField(
                            placeholder: "http://example.com",
                            field: app.state.gatewayURLField,
                            send: Address.forward(
                                send: app.send,
                                tag: AppAction.gatewayURLField
                            ),
                            caption: String(localized: "The URL of your preferred Noosphere gateway")
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .onDisappear {
                            app.send(.submitGatewayURLForm)
                        }
                        .disabled(app.state.gatewayOperationInProgress)
                        
                        ValidatedFormField(
                            placeholder: "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty-one twenty-two tenty-three twenty-four",
                            field: app.state.recoveryPhraseField,
                            send: Address.forward(
                                send: app.send,
                                tag: AppAction.recoveryPhraseField
                            ),
                            caption: "Recovery phrase",
                            axis: .vertical
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        
                        Button(
                            action: {
                                app.send(.requestRecovery)
                            },
                            label: {
                                AttemptRecoveryLabel(status: app.state.recoveryStatus)
                            }
                        )
                    },
                    header: {
                        Text("Recovery")
                    }
                )
            }
            .tabItem {
                Text("Form")
            }
            .tag(RecoveryViewTab.form)
        }
        .tabViewStyle(.page)
    }
}

enum RecoveryModeLaunchContext: Hashable {
    case unreadableDatabase
    case userInitiated
}

enum RecoveryModeAction: Hashable {
    case appear(RecoveryModeLaunchContext)
    case attemptRecovery(Did, URL, RecoveryPhrase)
    case succeedRecovery
    case failRecovery(_ error: String)
}

struct RecoveryModeModel: Hashable, ModelProtocol {
    typealias Action = RecoveryModeAction
    typealias Environment = AppEnvironment

    var launchContext: RecoveryModeLaunchContext = .userInitiated
    var recoveryStatus: ResourceStatus = .initial

    // Logger for actions
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DetailStackModel"
    )

    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case let .appear(context):
            var model = state
            model.launchContext = context
            return Update(state: model)
        case .attemptRecovery(let did, let gatewayUrl, let recoveryPhrase):
            return requestRecovery(
                state: state,
                environment: environment,
                did: did,
                gatewayUrl: gatewayUrl,
                recoveryPhrase: recoveryPhrase
            )
        case .succeedRecovery:
            return succeedRecovery(state: state, environment: environment)
        case .failRecovery(let error):
            return failRecovery(state: state, environment: environment, error: error)
        }
    }

    static func requestRecovery(
        state: Self,
        environment: Environment,
        did: Did,
        gatewayUrl: URL,
        recoveryPhrase: RecoveryPhrase
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached {
            guard try await environment.noosphere.recover(
                identity: did,
                gatewayUrl: gatewayUrl,
                mnemonic: recoveryPhrase
            ) else {
                return .failRecovery("Failed to recover identity")
            }
            
            return .succeedRecovery
        }
        .recover { error in
            .failRecovery(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        var model = state
        model.recoveryStatus = .pending
        return Update(state: model, fx: fx)
    }
    
    static func succeedRecovery(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        var model = state
        model.recoveryStatus = .succeeded
        return Update(state: model)
    }
                
    static func failRecovery(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        var model = state
        model.recoveryStatus = .failed(error)
        return Update(state: model)
    }
}
