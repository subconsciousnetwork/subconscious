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
    case done
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
            selection: Binding(
                get: { store.state.selectedTab },
                send: store.send,
                tag: RecoveryModeAction.setCurrentTab
            )
        ) {
            VStack(spacing: AppTheme.padding) {
                Text("Recovery Mode")
                    .bold()
                
                Spacer()
                
                switch store.state.launchContext {
                case .unreadableDatabase:
                    if let did = did {
                        ZStack {
                            StackedGlowingImage() {
                                GenerativeProfilePic(
                                    did: did,
                                    size: 128
                                )
                            }
                            .padding(AppTheme.padding)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                                .offset(x: 48, y: 48)
                                .foregroundColor(.secondary)
                        }
                        .padding([.bottom], AppTheme.padding)
                    }
                    Text("Your local data is unreadable.")
                        .multilineTextAlignment(.center)
                    Text(
                        "Subconscious will attempt to " +
                        "recover your data from your gateway, using your recovery phrase."
                    )
                    .multilineTextAlignment(.center)
                case .userInitiated:
                    if let did = did {
                        StackedGlowingImage() {
                            ZStack {
                                Image(systemName: "stethoscope")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 128, height: 128)
                                    .foregroundColor(.secondary)
                                    .offset(x: -16)
                                GenerativeProfilePic(
                                    did: did,
                                    size: 64
                                )
                                .offset(x: 52, y: 52)
                            }
                        }
                        .padding(AppTheme.padding)
                    }
                    Spacer()
                    Text(
                        "If your local data is damaged or unavailable you can recover your " +
                        "data from your gateway using your recovery phrase."
                    )
                    .multilineTextAlignment(.center)
                    
                }
                
                Text(
                    "We'll download and restore from the remote copy of your notes."
                )
                .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(
                    action: {
                        store.send(.setCurrentTab(.form))
                    },
                    label: {
                        Text("Proceed")
                    }
                )
                .buttonStyle(PillButtonStyle())
                
                if store.state.launchContext != .unreadableDatabase {
                    Button(
                        action: {
                            app.send(.presentRecoveryMode(false))
                        },
                        label: {
                            Text("Cancel")
                        }
                    )
                }
            }
            .padding(AppTheme.padding)
            .tabItem {
                Text("Recovery")
            }
            .tag(RecoveryViewTab.explain)
            
            VStack {
                Text("Recovery")
                    .bold()
                
                Spacer()
                
                Section(
                    content: {
                        ValidatedFormField(
                            placeholder: "did:key:abc",
                            field: store.state.recoveryDidField,
                            send: Address.forward(
                                send: store.send,
                                tag: RecoveryModeAction.recoveryDidField
                            ),
                            caption: "The identity of your sphere",
                            axis: .vertical
                        )
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        
                        ValidatedFormField(
                            placeholder: "http://example.com",
                            field: app.state.gatewayURLField,
                            send: Address.forward(
                                send: app.send,
                                tag: AppAction.gatewayURLField
                            ),
                            caption: String(localized: "The URL of your preferred Noosphere gateway"),
                            axis: .vertical
                        )
                        .textFieldStyle(.roundedBorder)
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
                            field: store.state.recoveryPhraseField,
                            send: Address.forward(
                                send: store.send,
                                tag: RecoveryModeAction.recoveryPhraseField
                            ),
                            caption: "Recovery phrase",
                            axis: .vertical
                        )
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        
                        Spacer()
                        
                        if case .failed(let error) = store.state.recoveryStatus {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(
                            action: {
                                if store.state.recoveryStatus == .succeeded {
                                    app.send(.presentRecoveryMode(false))
                                    return
                                }
                                
                                guard let did = store.state.recoveryDidField.validated else {
                                    return
                                }
                                
                                guard let gatewayUrl = app.state.gatewayURLField.validated else {
                                    return
                                }
                                
                                guard let recoveryPhrase = store.state.recoveryPhraseField.validated else {
                                    return
                                }
                                
                                store.send(.attemptRecovery(did, gatewayUrl, recoveryPhrase))
                            },
                            label: {
                                AttemptRecoveryLabel(status: store.state.recoveryStatus)
                            }
                        )
                        .buttonStyle(PillButtonStyle())
                        .disabled(
                            !store.state.recoveryDidField.isValid ||
                            !app.state.gatewayURLField.isValid ||
                            !store.state.recoveryPhraseField.isValid
                        )
                    })
            }
            .disabled(store.state.recoveryStatus == .pending)
            .padding(AppTheme.padding)
            .tabItem {
                Text("Form")
            }
            .tag(RecoveryViewTab.form)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

enum RecoveryModeLaunchContext: Hashable {
    case unreadableDatabase
    case userInitiated
}

enum RecoveryModeAction: Hashable {
    case recoveryPhraseField(RecoveryPhraseFormField.Action)
    case recoveryDidField(RecoveryDidFormField.Action)
    
    case appear(RecoveryModeLaunchContext)
    case presented(Bool)
    case setCurrentTab(RecoveryViewTab)
    case attemptRecovery(Did, URL, RecoveryPhrase)
    case succeedRecovery
    case failRecovery(_ error: String)
}

typealias RecoveryPhraseFormField = FormField<String, RecoveryPhrase>
typealias RecoveryDidFormField = FormField<String, Did>

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


struct RecoveryModeModel: ModelProtocol {
    typealias Action = RecoveryModeAction
    typealias Environment = AppEnvironment

    var presented: Bool = false
    var launchContext: RecoveryModeLaunchContext = .unreadableDatabase
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
        case let .appear(context):
            var model = state
            model.recoveryStatus = .initial
            model.launchContext = context
            return update(
                state: model,
                actions: [
                    .setCurrentTab(.explain),
                    .recoveryPhraseField(.reset),
                ],
                environment: environment
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
        return update(
            state: model,
            action: .recoveryPhraseField(.reset),
            environment: environment
        )
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

struct RecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RecoveryView(app: Store(state: AppModel(), environment: AppEnvironment()))
        }
    }
}
