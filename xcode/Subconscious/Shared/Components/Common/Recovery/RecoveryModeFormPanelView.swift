//
//  RecoveryPanelFormView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 25/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct RecoveryModeFormPanelView: View {
    var store: ViewStore<RecoveryModeModel>
    
    var formIsValid: Bool {
        store.state.recoveryDidField.isValid &&
        store.state.recoveryGatewayURLField.isValid &&
        store.state.recoveryPhraseField.isValid
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
    
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
                field: store.state.recoveryGatewayURLField,
                send: Address.forward(
                    send: store.send,
                    tag: RecoveryModeAction.recoveryGatewayURLField
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
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button(
                action: {
                    // Dismiss recovery if already succeeded
                    if store.state.recoveryStatus == .succeeded {
                        store.send(.requestPresent(false))
                        return
                    }
                    
                    guard let did = store.state.recoveryDidField.validated else {
                        return
                    }
                    
                    let gatewayField = store.state.recoveryGatewayURLField
                    guard let gatewayUrl = gatewayField.validated else {
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
        }
        .disabled(store.state.recoveryStatus == .pending)
        .padding(AppTheme.padding)
        .navigationTitle("Recovery")

    }
}
