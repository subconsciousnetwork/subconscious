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
    var store: ViewStore<FollowNewUserFormSheetModel>
    // TODO: should be copied into this model
    var did: Did?
    
    var form: FollowUserFormModel {
        get { store.state.form }
    }
    
    var formIsValid: Bool {
        form.did.isValid && form.petname.isValid
    }
    
    func onQRCodeScanResult(res: Result<ScanResult, ScanError>) {
        switch res {
        case .success(let result):
            store.send(.qrCodeScanned(scannedContent: result.string))
        case .failure(let error):
            store.send(.qrCodeScanError(error: error.localizedDescription))
        }
    }
    
    func onAttemptFollow() {
        guard let did = form.did.validated else {
            return
        }
        guard let name = form.petname.validated else {
            return
        }
        
        store.send(.attemptFollow(did, name.toPetname()))
    }
    
    func onCancel() { 
        store.send(.dismissSheet)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    FollowUserFormView(
                        store: store.viewStore(
                            get: \.form,
                            tag: FollowUserFormCursor.tag
                        )
                    )
                    
                    Section(header: Text("Add via QR Code")) {
                        Button(
                            action: {
                                store.send(.presentQRCodeScanner(true))
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
                        Section(header: Text("Your DID")) {
                            DidView(did: did)
                        }
                        
                        Section(header: Text("Your QR Code")) {
                            ShareableDidQrCodeView(did: did, color: Color.gray)
                        }
                    }
                }
                .navigationTitle("Follow User")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onAttemptFollow()
                        }
                        .disabled(!formIsValid)
                    }
                    ToolbarItem(placement: .navigation) {
                        Button("Cancel", role: .cancel) {
                            onCancel()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .fullScreenCover(
                isPresented: store.binding(
                    get: \.isQrCodeScannerPresented,
                    tag: FollowNewUserFormSheetAction.presentQRCodeScanner
                )
            ) {
                FollowUserViaQRCodeView(
                    onScanResult: onQRCodeScanResult,
                    onCancel: { store.send(.presentQRCodeScanner(false)) },
                    errorMessage: store.state.failQRCodeScanErrorMessage
                )
            }
        }
    }
}

struct FollowNewUserFormSheetView_Previews: PreviewProvider {
    static var previews: some View {
        FollowNewUserFormSheetView(
            store: Store(
                state: FollowNewUserFormSheetModel(),
                environment: AppEnvironment()
            ).toViewStore(),
            did: Did("did:key:123")!
        )
    }
}

// MARK: Actions
enum FollowNewUserFormSheetAction {
    case form(FollowUserFormAction)
    
    case presentQRCodeScanner(_ isPresented: Bool)
    case qrCodeScanned(scannedContent: String)
    case qrCodeScanError(error: String)
    
    case attemptToFindUniquePetname(petname: Petname.Name)
    case succeedFindUniquePetname(petname: Petname.Name)
    case failToFindUniquePetname(_ error: String)
    
    case attemptFollow(Did, Petname)
    case dismissSheet
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
            logger.warning("Failed to find a unique petname: \(error)")
            // We do not need to surface an error to the UI here.
            // If we tried to find a unique name in the first place then
            // the input field will already be marked as invalid and have
            // the caption changed to the message "Petname already in use" or whatever
            // the localizedDescription for the relevant AddressBookServiceError.
            return Update(state: state)
        case .dismissSheet:
            // Handled by FollowNewUserFormSheetCursor.tag
            return Update(state: state)
        case .attemptFollow:
            // Handled by FollowNewUserFormSheetCursor.tag
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
        switch action {
        case let .attemptFollow(did, petname):
            return UserProfileDetailAction.attemptFollow(did, petname)
        case .dismissSheet:
            return UserProfileDetailAction.presentFollowNewUserFormSheet(false)
        default:
            return UserProfileDetailAction.followNewUserFormSheet(action)
        }
    }
}


// MARK: Inner FollowUserForm
struct FollowUserFormView: View {
    var store: ViewStore<FollowUserFormModel>
    
    var petnameCaption: String {
        store.state.failFollowMessage ?? "Lowercase letters, numbers and dashes only."
    }
    
    var body: some View {
        Section(header: Text("User To Follow")) {
            HStack(alignment: .top) {
                Image(systemName: "key")
                    .foregroundColor(.accentColor)
                
                ValidatedFormField(
                    placeholder: "DID",
                    field: store.viewStore(
                        get: \.did,
                        tag: FollowUserFormAction.didField
                    ),
                    caption: String(
                        localized: "e.g. did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
                    ),
                    axis: .vertical
                )
                .lineLimit(12)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            }
            
            HStack(alignment: .top) {
                Image(systemName: "at")
                    .foregroundColor(.accentColor)
                
                ValidatedFormField(
                    placeholder: "petname",
                    field: store.viewStore(
                        get: \.petname,
                        tag: FollowUserFormAction.petnameField
                    ),
                    caption: petnameCaption
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

private struct PetnameFieldCursor: CursorProtocol {
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

private struct DidFieldCursor: CursorProtocol {
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
