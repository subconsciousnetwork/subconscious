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
        VStack(alignment: .center, spacing: AppTheme.padding) {
            Spacer()
            
            Text(
                "Enter your 24-word recovery phrase to download and restore your data."
            )
            .expandAlignedLeading()
            
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
            
            DisclosureGroup(
                "Sphere Details",
                isExpanded: store.binding(
                    get: \.isSphereDetailExpanded,
                    tag: RecoveryModeAction.setSphereDetailExpanded
                )
            ) {
                VStack(spacing: AppTheme.padding) {
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
                    .tint(.accentColor)

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
                    .tint(.accentColor)
                }
                .padding([.top], AppTheme.unit2)
            }
            .tint(.secondary)
            
            Spacer()
            
            if case .failed(let error) = store.state.recoveryStatus {
                Text(error)
                    .foregroundColor(.red)
                    .textSelection(.enabled)
            }
            
            Button(
                action: {
                    store.send(.pressRecoveryButton)
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RecoveryModeFormPanel_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RecoveryModeFormPanelView(
                store: Store(
                    state: RecoveryModeModel(
                        launchContext: .unreadableDatabase("Hello world"),
                        recoveryStatus: .failed("Test message"),
                        isSphereDetailExpanded: true,
                        recoveryDidField: RecoveryDidFormField(
                            value: "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                            validate: { x in Did(x) })
                    ),
                    environment: AppEnvironment()
                )
                .viewStore(
                    get: { x in x},
                    tag: { x in x }
                )
            )
        }

        NavigationStack {
            RecoveryModeFormPanelView(
                store: Store(
                    state: RecoveryModeModel(
                        launchContext: .unreadableDatabase("Hello world"),
                        recoveryStatus: .initial,
                        isSphereDetailExpanded: false,
                        recoveryDidField: RecoveryDidFormField(
                            value: "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                            validate: { x in Did(x) })
                    ),
                    environment: AppEnvironment()
                )
                .viewStore(
                    get: { x in x},
                    tag: { x in x }
                )
            )
        }    }
}
