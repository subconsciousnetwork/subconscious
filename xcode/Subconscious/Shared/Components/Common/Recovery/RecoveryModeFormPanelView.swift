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
                "Enter your recovery phrase:"
            )
            .font(.headline)
            .expandAlignedLeading()
            
            ValidatedFormField(
                placeholder: "one two three four five six seven eight...",
                field: store.viewStore(
                    get: \.recoveryPhraseField,
                    tag: RecoveryPhraseFormFieldCursor.tag
                ),
                axis: .vertical
            )
            .font(.body.monospaced())
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            
            Text(
                "This is the 24-word recovery phrase you saved when you first set up Subconscious."
            )
            .font(.callout)
            .foregroundColor(.secondary)
            .expandAlignedLeading()

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
                        field: store.viewStore(
                            get: \.recoveryDidField,
                            tag: RecoveryDidFormFieldCursor.tag
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
                        field: store.viewStore(
                            get: \.recoveryGatewayURLField,
                            tag: RecoveryGatewayURLFormFieldCursor.tag
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
        .navigationTitle("Recover Sphere")
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
                        recoveryPhraseField: RecoveryPhraseFormField(
                            value: "hotel obvious agent lecture gadget evil jealous keen fragile before damp clarify hotel obvious agent lecture gadget evil jealous keen fragile before damp clarify",
                            validate: { x in RecoveryPhrase(x) }
                        ),
                        recoveryDidField: RecoveryDidFormField(
                            value: "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                            validate: { x in Did(x) }
                        )
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
