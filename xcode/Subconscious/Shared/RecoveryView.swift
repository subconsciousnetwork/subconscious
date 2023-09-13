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

// MARK: Actions
enum RecoveryViewAction {
    case appear
    case setRecoveryMode(Bool)
}

struct RecoveryEnvironment {
    var applicationSupportURL: URL
    var database: DatabaseService
    
    func attemptNoosphere() async -> Bool {
        let globalStorageURL = applicationSupportURL.appending(
            path: Config.default.noosphere.globalStoragePath
        )
        let sphereStorageURL = applicationSupportURL.appending(
            path: Config.default.noosphere.sphereStoragePath
        )
        let defaultGateway = URL(string: AppDefaults.standard.gatewayURL)
        let defaultSphereIdentity = AppDefaults.standard.sphereIdentity

        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL,
            gatewayURL: defaultGateway,
            sphereIdentity: defaultSphereIdentity
        )
        
        do {
            let x = try await noosphere.identity()
            return true
        
        } catch {
            let e = error.localizedDescription
            print(e)
            return false
        }
    }
    
    init() {
        self.applicationSupportURL = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let databaseURL = self.applicationSupportURL
            .appendingPathComponent("database.sqlite")

        let database = DatabaseService(
            database: SQLite3Database(
                path: databaseURL.absoluteString,
                mode: .readwrite
            ),
            migrations: Config.migrations
        )
        self.database = database
    }
}

// MARK: Model
struct RecoveryViewModel: ModelProtocol {
    typealias Action = RecoveryViewAction
    typealias Environment = AppEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "RecoveryViewModel"
    )
    
    var recovery = false
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch (action) {
        case .setRecoveryMode(let recovery):
            var model = state
            model.recovery = recovery
            return Update(state: model)
        case .appear:
            return Update(state: state)
        }
    }
}

