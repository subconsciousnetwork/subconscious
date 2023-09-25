//
//  RecoveryTabFormView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 25/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct RecoveryTabFormView: View {
    var app: Store<AppModel>
    var store: ViewStore<RecoveryModeModel>
    
    var formIsValid: Bool {
        store.state.recoveryDidField.isValid &&
        app.state.gatewayURLField.isValid &&
        store.state.recoveryPhraseField.isValid
    }
    
    var body: some View {
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
                    
                    ValidatedFormField(
                        placeholder: "one two three four five six seven eight...",
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
                        ErrorDetailView(error: error)
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
                            
                            let phraseField = store.state.recoveryPhraseField
                            guard let recoveryPhrase = phraseField.validated else {
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
                        store.state.recoveryStatus != .succeeded && !formIsValid
                    )
                })
        }
        .disabled(store.state.recoveryStatus == .pending)
        .padding(AppTheme.padding)
    }
}
