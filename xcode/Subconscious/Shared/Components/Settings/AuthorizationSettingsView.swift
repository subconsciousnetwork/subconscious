//
//  AuthorizationSettingsView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/7/2023.
//

import SwiftUI
import ObservableStore
import Combine
import os

struct AuthorizationView: View {
    var authorization: Authorization
    
    var body: some View {
        ShareLink(item: authorization) {
            HStack {
                Text(authorization)
                    .font(.callout.monospaced())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: AppTheme.unit2)
                
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

struct AuthorizationSettingsView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        Form {
            if let lastAuth = app.state.authorization.lastAuthorization {
                Section(
                    content: {
                        AuthorizationView(authorization: lastAuth)
                    },
                    header: { Text("Authorization Code") },
                    footer: { }
                )
            }
            
            Section(
                content: {
                    
                    ValidatedFormField(
                        placeholder: "DID",
                        field: app.state.authorization.form.did,
                        send: Address.forward(
                            send: app.send,
                            tag: { a in .authorization(.form(.didField(a))) }
                        ),
                        caption: Text(
                            "e.g. did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
                        ),
                        axis: .vertical
                    )
                    .lineLimit(12)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    
                    ValidatedFormField(
                        placeholder: "name",
                        field: app.state.authorization.form.name,
                        send: Address.forward(
                            send: app.send,
                            tag: { a in .authorization(.form(.nameField(a))) }
                        ),
                        caption: Text(
                            "The name for this authorization"
                        )
                    )
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    
                    Button(
                        action: {
                            app.send(.authorization(.submitAuthorizeForm))
                        },
                        label: {
                            Label(
                                title: {
                                    Text("Authorize")
                                },
                                icon: {
                                    Image(systemName: "person.badge.key")
                               }
                            )
                        }
                    )
                }, header: {
                    Text("Authorization Settings")
                }, footer: {
                    if let message = app.state.authorization.errorMessage {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                })
            
            Section(
                content: {
                    List {
                        ForEach(app.state.authorization.authorizations, id: \.self) { auth in
                            HStack {
                                Text(auth)
                                    .font(.callout.monospaced())
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                Menu(
                                    content: {
                                        Button(
                                            action: {
                                                app.send(.authorization(.requestRevoke(auth)))
                                            },
                                            label: {
                                                Label(
                                                    title: { Text("Revoke") },
                                                    icon: { Image(systemName: "exclamationmark.octagon.fill") }
                                                )
                                            }
                                        )
                                    },
                                    label: {
                                        EllipsisLabelView()
                                    }
                                )
                            }
                        }
                    }
                },
                header: { Text("Authorizations") }
            )
        }
        .confirmationDialog(
            "This may revoke other authorizations that depend on this authorization, are you sure?",
            isPresented:
                Binding(
                    get: { app.state.authorization.isConfirmRevokePresented },
                    set: { _ in app.send(.authorization(.presentRevokeConfirmation(false))) }
                )
        ) {
            Button(
                "Revoke Authorization",
                role: .destructive
            ) {
                app.send(.authorization(.confirmRevoke))
            }
        } message: {
            Text("You cannot undo this action")
        }
        .navigationTitle("Authorization Settings")
        .onAppear {
            app.send(.authorization(.appear))
        }
        .onReceive(app.actions) { action in
            switch action {
            case .authorization(.succeedAuthorize(_)):
                app.send(.syncAll)
                break
            case _:
                break
            }
        }
    }
}

struct AuthorizationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AuthorizationSettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}

enum AuthorizationSettingsFormAction: Equatable {
    case didField(FormFieldAction<String>)
    case nameField(FormFieldAction<String>)
    case reset
}

struct AuthorizationSettingsFormModel: ModelProtocol {
    typealias Action = AuthorizationSettingsFormAction
    typealias Environment = ()
    
    var did: FormField<String, Did> = FormField(
        value: "",
        validate: Self.validateDid
    )
    
    var name: FormField<String, String> = FormField(
        value: "",
        validate: Self.validateName
    )
    
    static func validateDid(key: String) -> Did? {
        Did(key)
    }

    static func validateName(name: String) -> String? {
        name
    }
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .didField(let action):
            return DidFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .nameField(let action):
            return NameFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .reset:
            return update(
                state: state,
                actions: [
                    .didField(.reset),
                    .nameField(.reset)
                ],
                environment: environment
            )
        }
    }
}

// MARK: Actions
enum AuthorizationSettingsAction {
    case appear
    case listAuthorizations
    case succeedListAuthorizations([Authorization])
    case failListAuthorizations(_ error: String)
    
    case form(AuthorizationSettingsFormAction)
    case submitAuthorizeForm
    case succeedAuthorize(Authorization)
    case failAuthorize(_ error: String)
    
    case presentQRCodeScanner(_ isPresented: Bool)
    case qrCodeScanned(scannedContent: String)
    case qrCodeScanError(error: String)
    
    case requestRevoke(Authorization)
    case confirmRevoke
    case cancelRevoke
    case succeedRevoke
    case failRevoke(_ error: String)

    case presentRevokeConfirmation(Bool)
}

typealias AuthorizationSettingsEnvironment = AppEnvironment

// MARK: Model
struct AuthorizationSettingsModel: ModelProtocol {
    typealias Action = AuthorizationSettingsAction
    typealias Environment = FollowNewUserFormSheetEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AuthorizationSettingsModel"
    )
    
    var isQrCodeScannerPresented = false
    var isConfirmRevokePresented = false
    
    var form: AuthorizationSettingsFormModel = AuthorizationSettingsFormModel()
    var authorizations: [Authorization] = ["Test"]
    
    var errorMessage: String? = nil
    var lastAuthorization: Authorization? = nil
    
    var revokeCandidate: Authorization? = nil
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch (action) {
        case .form(let action):
            return AuthorizationSettingsFormCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .appear:
            var model = state
            model.errorMessage = nil
            model.lastAuthorization = nil
            return update(
                state: model,
                actions: [.listAuthorizations, .form(.reset)],
                environment: environment
            )
        case .listAuthorizations:
            let fx: Fx<AuthorizationSettingsAction> = Future.detached {
                do {
                    let authorizations = try await environment.noosphere.listAuthorizations()
                    return .succeedListAuthorizations(authorizations)
                } catch {
                    return .failListAuthorizations(error.localizedDescription)
                }
            }.eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        case .succeedListAuthorizations(let authorizations):
            var model = state
            model.authorizations = authorizations
            
            return Update(state: model).animation(.easeOutCubic())
        case .failListAuthorizations(let message):
            var model = state
            model.errorMessage = message
            logger.error("Failed to list authorizations: \(message)")
            return Update(state: model)
            
        case .presentQRCodeScanner(let isPresented):
            var model = state
            model.isQrCodeScannerPresented = isPresented
            return Update(state: model)
            
        case .qrCodeScanned(scannedContent: let content):
            return update(
                state: state,
                actions: [
                    .form(.didField(.reset)),
                    .form(.didField(.setValue(input: content)))
                ],
                environment: environment
            )
            
        case .qrCodeScanError(error: let error):
            var model = state
            model.errorMessage = error
            return Update(state: model)
            
        case .submitAuthorizeForm:
            guard let did = state.form.did.validated else {
                return Update(state: state)
            }
            
            guard let name = state.form.name.validated else {
                return Update(state: state)
            }
            
            let fx: Fx<AuthorizationSettingsAction> = Future.detached {
                do {
                    let auth = try await environment
                        .noosphere
                        .authorize(name: name, did: did)
                    
                    let _ = try await environment.noosphere.save()
                    
                    return .succeedAuthorize(auth)
                } catch {
                    return .failAuthorize(error.localizedDescription)
                }
            }.eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        case .succeedAuthorize(let auth):
            var model = state
            model.lastAuthorization = auth
            logger.log("authorize succeeded!", metadata: ["auth": auth])
            return update(
                state: model,
                actions: [.listAuthorizations, .form(.reset)],
                environment: environment
            ).animation(.easeOutCubic())
        case .failAuthorize(let message):
            var model = state
            model.errorMessage = message
            logger.log("authorize failed: \(message)")
            return Update(state: model)
        case .requestRevoke(let auth):
            var model = state
            model.revokeCandidate = auth
            model.isConfirmRevokePresented = true
            return Update(state: model)
        case .confirmRevoke:
            var model = state
            model.isConfirmRevokePresented = false
            
            guard let candidate = state.revokeCandidate else {
                return Update(state: model)
            }
            
            model.revokeCandidate = nil
            
            let fx: Fx<AuthorizationSettingsAction> = Future.detached {
                do {
                    try await environment.noosphere.revoke(authorization: candidate)
                    let _ = try await environment.noosphere.save()
                    return .succeedRevoke
                } catch {
                    return .failRevoke(error.localizedDescription)
                }
            }.eraseToAnyPublisher()
            
            return Update(state: model, fx: fx)
        case .cancelRevoke:
            var model = state
            model.isConfirmRevokePresented = false
            model.revokeCandidate = nil
            return Update(state: model)
        case .succeedRevoke:
            logger.error("Revoked!")
            return update(state: state, action: .listAuthorizations, environment: environment)
        case .failRevoke(let message):
            var model = state
            model.errorMessage = message
            logger.error("Fail to revoke: \(message)")
            return Update(state: model)
        case .presentRevokeConfirmation(let presented):
            var model = state
            model.isConfirmRevokePresented = presented
            return Update(state: model)
        }
    }
}

// MARK: Cursors

struct AuthorizationSettingsCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = AuthorizationSettingsModel

    static func get(state: Model) -> ViewModel {
        state.authorization
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.authorization = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .authorization(action)
    }
}

struct AuthorizationSettingsFormCursor: CursorProtocol {
    typealias Model = AuthorizationSettingsModel
    typealias ViewModel = AuthorizationSettingsFormModel

    static func get(state: Model) -> ViewModel {
        state.form
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.form = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .form(action)
    }
}

private struct DidFieldCursor: CursorProtocol {
    typealias Model = AuthorizationSettingsFormModel
    typealias ViewModel = FormField<String, Did>

    static func get(state: Model) -> ViewModel {
        state.did
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.did = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .didField(action)
    }
}

private struct NameFieldCursor: CursorProtocol {
    typealias Model = AuthorizationSettingsFormModel
    typealias ViewModel = FormField<String, String>

    static func get(state: Model) -> ViewModel {
        state.name
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.name = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .nameField(action)
    }
}
