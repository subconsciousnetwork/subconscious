//
//  FollowUserFormView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import os
import SwiftUI
import ObservableStore
import CodeScanner

struct FollowNewUserFormSheetView: View {
    var state: FollowNewUserFormSheetModel
    var form: FollowUserFormModel {
        get { state.form }
    }
    var send: (FollowNewUserFormSheetAction) -> Void
    
    var did: Did?
    
    var onAttemptFollow: () -> Void
    var onCancel: () -> Void
    
    var onDismissFailFollowError: () -> Void
    
    func onQRCodeScanResult(res: Result<ScanResult, ScanError>) {
        switch res {
        case .success(let result):
            send(.qrCodeScanned(scannedContent: result.string))
        case .failure(let error):
            send(.qrCodeScanError(error: error.localizedDescription))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    FollowUserFormView(
                        state: form,
                        send: Address.forward(
                            send: send,
                            tag: FollowUserFormCursor.tag
                        )
                    )
                    
                    if Config.default.addByQRCode {
                        Section(header: Text("Add via QR Code")) {
                            Button(
                                action: {
                                    send(.presentQRCodeScanner(true))
                                },
                                label: {
                                    HStack {
                                        Image(systemName: "qrcode")
                                        Text("Scan Code")
                                    }
                                    .foregroundColor(.accentColor)
                                }
                            )
                        }
                        
                        if let did = did {
                            Section(header: Text("Your QR Code")) {
                                VStack {
                                    DidQrCodeView(did: did, color: Color.gray)
                                        .frame(maxWidth: 256)
                                    DidView(did: did)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Follow User")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onAttemptFollow()
                        }
                    }
                    ToolbarItem(placement: .navigation) {
                        Button("Cancel", role: .cancel) {
                            onCancel()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .alert(
                isPresented: Binding(
                    get: { state.failFollowErrorMessage != nil },
                    set: { _ in onDismissFailFollowError() }
                )
            ) {
                Alert(
                    title: Text("Failed to Follow User"),
                    message: Text(state.failFollowErrorMessage ?? "An unknown error ocurred")
                )
            }
            .fullScreenCover(
                isPresented: Binding(
                    get: { state.isQrCodeScannerPresented && Config.default.addByQRCode },
                    send: send,
                    tag: FollowNewUserFormSheetAction.presentQRCodeScanner
                )
            ) {
                FollowUserViaQRCodeView(
                    onScanResult: onQRCodeScanResult,
                    onCancel: { send(.presentQRCodeScanner(false)) },
                    errorMessage: state.failQRCodeScanErrorMessage
                )
            }
        }
    }
}

struct FollowNewUserFormSheetView_Previews: PreviewProvider {
    static var previews: some View {
        FollowNewUserFormSheetView(
            state: FollowNewUserFormSheetModel(),
            send: { action in },
            did: Did("did:key:123")!,
            onAttemptFollow: {},
            onCancel: {},
            onDismissFailFollowError: {}
        )
    }
}

// MARK: Actions
enum FollowNewUserFormSheetAction {
    case form(FollowUserFormAction)
    
    case presentQRCodeScanner(_ isPresented: Bool)
    case qrCodeScanned(scannedContent: String)
    case qrCodeScanError(error: String)
    
    case failFollow(error: String, petname: Petname.Name)
    case attemptToFindUniquePetname(petname: Petname.Name)
    case succeedFindUniquePetname(petname: Petname.Name)
    case failToFindUniquePetname(_ error: String)
}

typealias FollowNewUserFormSheetEnvironment = AppEnvironment

// MARK: Model
struct FollowNewUserFormSheetModel: ModelProtocol {
    typealias Action = FollowNewUserFormSheetAction
    typealias Environment = FollowNewUserFormSheetEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "FollowNewUserFormSheetModel"
    )
    
    var isQrCodeScannerPresented = false
    
    var form: FollowUserFormModel = FollowUserFormModel()
    
    var failFollowErrorMessage: String? = nil
    var failQRCodeScanErrorMessage: String? = nil
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch (action) {
        case .form(let action):
            return FollowUserFormCursor.update(
                state: state,
                action: action,
                environment: ()
            )
            
        case .presentQRCodeScanner(let isPresented):
            var model = state
            model.failQRCodeScanErrorMessage = nil
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
            model.failQRCodeScanErrorMessage = error
            return Update(state: model)
            
        case .failFollow(let error, let petname):
            return update(
                state: state,
                actions: [
                    .attemptToFindUniquePetname(petname: petname),
                    .form(.failFollow(error))
                ],
                environment: environment
            )
            
        case .attemptToFindUniquePetname(let petname):
            let fx: Fx<FollowNewUserFormSheetAction> = environment
                .addressBook
                .findAvailablePetnamePublisher(name: petname)
                .map { petname in
                    .succeedFindUniquePetname(petname: petname)
                }
                .recover { error in
                    .failToFindUniquePetname(error.localizedDescription)
                }
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        case .succeedFindUniquePetname(let petname):
            return update(
                state: state,
                action: .form(
                    .petnameField(.setValue(input: petname.verbatim))
                ),
                environment: environment
            )
        case .failToFindUniquePetname(let error):
            // Not a huge deal, the user will have to enter a name themselves
            logger.warning("Failed to find a unique petname: \(error)")
            return Update(state: state)
        }
    }
}

// MARK: Cursors

struct FollowUserFormCursor: CursorProtocol {
    typealias Model = FollowNewUserFormSheetModel
    typealias ViewModel = FollowUserFormModel

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

struct FollowNewUserFormSheetCursor: CursorProtocol {
    typealias Model = UserProfileDetailModel
    typealias ViewModel = FollowNewUserFormSheetModel

    static func get(state: Model) -> ViewModel {
        state.followNewUserFormSheet
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.followNewUserFormSheet = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        .followNewUserFormSheet(action)
    }
}


// MARK: Inner FollowUserForm
struct FollowUserFormView: View {
    var state: FollowUserFormModel
    var send: (FollowUserFormAction) -> Void
    
    var body: some View {
        Section(header: Text("User To Follow")) {
            HStack(alignment: .top) {
                Image(systemName: "key")
                    .foregroundColor(.accentColor)
                
                ValidatedFormField(
                    placeholder: "DID",
                    field: state.did,
                    send: Address.forward(
                        send: send,
                        tag: FollowUserFormAction.didField
                    ),
                    caption: "e.g. did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
                )
                .lineLimit(1)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            }
            
            HStack(alignment: .top) {
                Image(systemName: "at")
                    .foregroundColor(.accentColor)
                
                ValidatedFormField(
                    placeholder: "petname",
                    field: state.petname,
                    send: Address.forward(
                        send: send,
                        tag: FollowUserFormAction.petnameField
                    ),
                    caption: state.failFollowMessage ?? "Lowercase letters, numbers and dashes only."
                )
                .lineLimit(1)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            }
        }
    }
}

// MARK: Actions

enum FollowUserFormAction: Equatable {
    case didField(FormFieldAction<String>)
    case petnameField(FormFieldAction<String>)
    case failFollow(_ error: String)
    case reset
}

// MARK: Model

struct FollowUserFormModel: ModelProtocol {
    typealias Action = FollowUserFormAction
    typealias Environment = ()
    
    var did: FormField<String, Did> = FormField(
        value: "",
        validate: Self.validateDid
    )
    
    var petname: FormField<String, Petname.Name> = FormField(
        value: "",
        validate: Self.validatePetname
    )
    
    var failFollowMessage: String? = nil
    
    static func validateDid(key: String) -> Did? {
        Did(key)
    }

    static func validatePetname(petname: String) -> Petname.Name? {
        Petname.Name(petname)
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
        case .petnameField(let action):
            return PetnameFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .failFollow(let error):
            var model = state
            model.failFollowMessage = error
            return update(
                state: model,
                actions: [
                    .petnameField(.setValidationStatus(valid: false))
                ],
                environment: environment
            )
        case .reset:
            var model = state
            model.failFollowMessage = nil
            return update(
                state: model,
                actions: [
                    .didField(.reset),
                    .petnameField(.reset)
                ],
                environment: environment
            )
        }
    }
}

// MARK: Cursors

struct PetnameFieldCursor: CursorProtocol {
    typealias Model = FollowUserFormModel
    typealias ViewModel = FormField<String, Petname.Name>

    static func get(state: Model) -> ViewModel {
        state.petname
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.petname = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        FollowUserFormAction.petnameField(action)
    }
}

struct DidFieldCursor: CursorProtocol {
    typealias Model = FollowUserFormModel
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
        FollowUserFormAction.didField(action)
    }
}
