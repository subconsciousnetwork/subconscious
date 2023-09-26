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
            return "Try Again"
        case .succeeded:
            return "Complete"
        }
    }
    
    var body: some View {
        Label(title: {
            Text(label)
        }, icon: {
            ResourceSyncBadge(status: status)
        })
        .foregroundColor(.accentColor)
    }
}

enum RecoveryViewTab {
    case explain
    case form
}

struct RecoveryView: View {
    @ObservedObject var app: Store<AppModel>
    var store: ViewStore<RecoveryModeModel> {
        app.viewStore(get: RecoveryModeCursor.get, tag: RecoveryModeCursor.tag)
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var did: Did? {
        Did(app.state.sphereIdentity ?? "")
    }
    
    var body: some View {
        TabView(
            selection: store.binding(
                get: { state in state.selectedTab },
                tag: RecoveryModeAction.setCurrentTab
            )
        ) {
            RecoveryModeExplainPanelView(
                store: store,
                did: did,
                onCancel: {
                    app.send(.presentRecoveryMode(false))
                }
            )
            .tabItem {
                Text("Recovery")
            }
            .tag(RecoveryViewTab.explain)
            
            RecoveryModeFormPanelView(
                store: store,
                onDismiss: {
                    app.send(.presentRecoveryMode(false))
                }
            )
            .tabItem {
                Text("Form")
            }
            .tag(RecoveryViewTab.form)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

enum RecoveryModeLaunchContext: Hashable {
    case unreadableDatabase(_ error: String)
    case userInitiated
}

enum RecoveryModeAction: Hashable {
    case recoveryPhraseField(RecoveryPhraseFormField.Action)
    case recoveryDidField(RecoveryDidFormField.Action)
    case recoveryGatewayURLField(RecoveryGatewayURLFormField.Action)
    
    case populate(Did?, GatewayURL?, RecoveryModeLaunchContext)
    case presented(Bool)
    case setCurrentTab(RecoveryViewTab)
    case attemptRecovery(Did, GatewayURL, RecoveryPhrase)
    case succeedRecovery
    case failRecovery(_ error: String)
}

typealias RecoveryPhraseFormField = FormField<String, RecoveryPhrase>
typealias RecoveryDidFormField = FormField<String, Did>
typealias RecoveryGatewayURLFormField = FormField<String, GatewayURL>

struct RecoveryPhraseFormFieldCursor: CursorProtocol {
    typealias Model = RecoveryModeModel
    typealias ViewModel = RecoveryPhraseFormField
    
    static func get(state: Model) -> ViewModel {
        state.recoveryPhraseField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.recoveryPhraseField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .recoveryPhraseField(action)
        }
    }
}

struct RecoveryDidFormFieldCursor: CursorProtocol {
    typealias Model = RecoveryModeModel
    typealias ViewModel = RecoveryDidFormField
    
    static func get(state: Model) -> ViewModel {
        state.recoveryDidField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.recoveryDidField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .recoveryDidField(action)
        }
    }
}

struct RecoveryGatewayURLFormFieldCursor: CursorProtocol {
    typealias Model = RecoveryModeModel
    typealias ViewModel = RecoveryGatewayURLFormField
    
    static func get(state: Model) -> ViewModel {
        state.recoveryGatewayURLField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.recoveryGatewayURLField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .recoveryGatewayURLField(action)
        }
    }
}

struct RecoveryModeModel: ModelProtocol {
    typealias Action = RecoveryModeAction
    typealias Environment = AppEnvironment

    var presented: Bool = false
    var launchContext: RecoveryModeLaunchContext = .userInitiated
    var recoveryStatus: ResourceStatus = .initial
    var selectedTab: RecoveryViewTab = .explain
    
    var recoveryPhraseField = RecoveryPhraseFormField(
        value: "",
        validate: { value in RecoveryPhrase(value) }
    )
    
    var recoveryDidField = RecoveryDidFormField(
        value: "",
        validate: { value in Did(value) }
    )
    
    var recoveryGatewayURLField = GatewayUrlFormField(
        value: "",
        validate: { value in GatewayURL(value) }
    )

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
        case .recoveryPhraseField(let action):
            return RecoveryPhraseFormFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .recoveryDidField(let action):
            return RecoveryDidFormFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .recoveryGatewayURLField(let action):
            return RecoveryGatewayURLFormFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case let .populate(did, gatewayURL, context):
            return populate(
                state: state,
                environment: environment,
                did: did,
                gatewayURL: gatewayURL,
                context: context
            )
        case .presented(let presented):
            var model = state
            model.presented = presented
            return Update(state: model)
        case .setCurrentTab(let tab):
            var model = state
            model.selectedTab = tab
            return Update(state: model).animation(.default)
        case .attemptRecovery(let did, let gatewayUrl, let recoveryPhrase):
            return attemptRecovery(
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
    
    static func populate(
        state: Self,
        environment: Environment,
        did: Did?,
        gatewayURL: GatewayURL?,
        context: RecoveryModeLaunchContext
    ) -> Update<Self> {
        var model = state
        model.recoveryStatus = .initial
        model.launchContext = context
        return update(
            state: model,
            actions: [
                .setCurrentTab(.explain),
                .recoveryPhraseField(.reset),
                .recoveryDidField(.reset),
                .recoveryDidField(.setValue(input: did?.did ?? "")),
                .recoveryGatewayURLField(.reset),
                .recoveryGatewayURLField(.setValue(input: gatewayURL?.absoluteString ?? ""))
            ],
            environment: environment
        )
    }
    

    static func attemptRecovery(
        state: Self,
        environment: Environment,
        did: Did,
        gatewayUrl: GatewayURL,
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
        return Update(state: model).animation(.easeOutCubic())
    }
                
    static func failRecovery(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        var model = state
        model.recoveryStatus = .failed(error)
        return Update(state: model).animation(.easeOutCubic())
    }
}

struct RecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RecoveryView(app: Store(state: AppModel(), environment: AppEnvironment()))
        }
    }
}
