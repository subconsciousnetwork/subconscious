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

struct RecoveryView: View {
    @ObservedObject var app: Store<AppModel>
    
    var body: some View {
        NavigationStack {
            Form {
                Section(content: {
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
                            
                        },
                        label: {
                            Text("Attempt Recovery")
                        }
                    )
                }, header: {
                    Text("Recovery")
                }, footer: {
                    Text("If you ever lose your device or delete the application data, you can recover your data using your recovery phrase and your gateway.")
                })
                
                
                
            }
            .navigationTitle("Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        action: {
                            app.send(.presentRecovery(false))
                        },
                        label: {
                            Text("Cancel")
                        }
                    )
                }
            }
        }
    }
}
