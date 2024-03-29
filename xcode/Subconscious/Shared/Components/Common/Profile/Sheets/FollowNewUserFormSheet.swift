//
//  FollowNewUserFormSheet.swift
//  Subconscious
//
//  Created by Ben Follington on 3/11/2023.
//

import SwiftUI
import ObservableStore
import CodeScanner
import os
import Combine

struct FollowNewUserFormSheetView: View {
    var store: ViewStore<FollowNewUserFormSheetModel>
    
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
        store.send(.attemptFollow)
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
                            tag: FollowNewUserFormCursor.tag
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
                    
                    Section(header: Text("Suggestions")) {
                        ForEach(store.state.suggestions, id: \.identity) { suggestion in
                            Button(
                                action: {
                                    store.send(.requestFollowSuggestion(suggestion))
                                },
                                label: {
                                    HStack(spacing: AppTheme.unit2) {
                                        ProfilePic(
                                            pfp: .generated(suggestion.identity),
                                            size: .small
                                        )
                                        
                                        Text("\(suggestion.name.description)")
                                            .italic()
                                            .fontWeight(.medium)
                                    }
                                }
                            )
                        }
                    }
                    
                    if let did = store.state.did {
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
            ).toViewStoreForSwiftUIPreview()
        )
    }
}

// MARK: Actions
enum FollowNewUserFormSheetAction: Equatable {
    case form(FollowUserFormAction)
    
    case populate(_ did: Did)
    case presentQRCodeScanner(_ isPresented: Bool)
    case qrCodeScanned(scannedContent: String)
    case qrCodeScanError(error: String)
    
    case attemptToFindUniquePetname(petname: Petname.Name)
    case succeedFindUniquePetname(petname: Petname.Name)
    case failToFindUniquePetname(_ error: String)
    
    case attemptFollow
    case dismissSheet
    
    case requestFollowSuggestion(_ neighbor: NeighborRecord)
    
    case refreshSuggestions
    case succeedRefreshSuggestions(_ suggestions: [NeighborRecord])
    case failRefreshSuggestions(_ error: String)
}

typealias FollowNewUserFormSheetEnvironment = AppEnvironment

// MARK: Cursors

struct FollowNewUserFormCursor: CursorProtocol {
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
        case .attemptFollow:
            return UserProfileDetailAction.submitFollowNewUser
        case .dismissSheet:
            return UserProfileDetailAction.presentFollowNewUserFormSheet(false)
        default:
            return UserProfileDetailAction.followNewUserFormSheet(action)
        }
    }
}

// MARK: Model
struct FollowNewUserFormSheetModel: ModelProtocol {
    typealias Action = FollowNewUserFormSheetAction
    typealias Environment = FollowNewUserFormSheetEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "FollowNewUserFormSheetModel"
    )
    
    var did: Did? = nil
    var isQrCodeScannerPresented = false
    var suggestions: [NeighborRecord] = []
    
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
            return FollowNewUserFormCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .populate(let did):
            var model = state
            model.did = did
            return update(
                state: model,
                action: .refreshSuggestions,
                environment: environment
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
        case .refreshSuggestions:
            return refreshSuggestions(
                state: state,
                environment: environment
            )
        case let .succeedRefreshSuggestions(suggestions):
            return succeedRefreshSuggestions(
                state: state,
                environment: environment,
                suggestions: suggestions
            )
        case let .failRefreshSuggestions(error):
            logger.warning("Failed to refresh suggestions: \(error)")
            return Update(state: state)
        case let .requestFollowSuggestion(neighbor):
            return update(
                state: state,
                actions: [
                    .form(.didField(.setValue(input: neighbor.identity.description))),
                    .form(.petnameField(.setValue(input: neighbor.name.description)))
                ],
                environment: environment
            )
        }
    }
    
    static func refreshSuggestions(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached {
            let identity = try await environment.noosphere.identity()
            let suggestions = try environment.database.listNeighbors(owner: identity)
            return .succeedRefreshSuggestions(suggestions)
        }
        .recover { error in
            .failRefreshSuggestions(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedRefreshSuggestions(
        state: Self,
        environment: Environment,
        suggestions: [NeighborRecord]
    ) -> Update<Self> {
        var model = state
        model.suggestions = suggestions
        return Update(state: model)
    }
}
