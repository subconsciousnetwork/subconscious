//
//  AddressBookModel.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 6/3/2023.
//

import os
import Foundation
import SwiftUI
import ObservableStore
import Combine

struct AddressBookEntry: Equatable {
    var petname: Petname
    var did: Did
}

struct AddressBookEnvironment {
    // Default logger for environment
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AddressBook"
    )
    var logger: Logger = logger
    var noosphere: NoosphereService
    var data: DataService
    var addressBook: AddressBookService
}

struct FollowUserFormCursor_old: CursorProtocol {
    static func get(state: AddressBookModel) -> FollowUserFormModel {
        state.followUserForm
    }
    
    static func set(state: AddressBookModel, inner: FollowUserFormModel) -> AddressBookModel {
        var model = state
        model.followUserForm = inner
        return model
    }
    
    static func tag(_ action: FollowUserFormAction) -> AddressBookAction {
        AddressBookAction.followUserForm(action)
    }
}

enum AddressBookAction {
    case followUserForm(FollowUserFormAction)
    case present(_ isPresented: Bool)
    
    case refreshDid
    case succeedRefreshDid(Did)
    case failRefreshDid(_ error: String)
    
    case refreshEntries(forceRefetchFromNoosphere: Bool = false)
    case failRefreshEntries(_ error: String)
    case populate([AddressBookEntry])
    
    case requestFollow
    case attemptFollow
    case failFollow(error: String)
    case dismissFailFollowError
    case succeedFollow(did: Did, petname: Petname)
    
    case requestUnfollow(petname: Petname)
    case confirmUnfollow
    case cancelUnfollow
    case failUnfollow(error: String)
    case dismissFailUnfollowError
    case succeedUnfollow(petname: Petname)
    
    case presentFollowUserForm(_ isPresented: Bool)

    case presentQRCodeScanner(_ isPresented: Bool)
    case qrCodeScanned(scannedContent: String)
    case qrCodeScanError(error: String)
}

struct AddressBookModel: ModelProtocol {
    var isPresented = false
    var did: Did? = nil
    var follows: [AddressBookEntry] = []
    
    var isFollowUserFormPresented = false
    var followUserForm = FollowUserFormModel()
    
    var failFollowErrorMessage: String? = nil
    var failUnfollowErrorMessage: String? = nil
    var failQRCodeScanErrorMessage: String? = nil
    
    var unfollowCandidate: Petname? = nil
    
    var isQrCodeScannerPresented = false
    
    static func update(
        state: AddressBookModel,
        action: AddressBookAction,
        environment: AddressBookEnvironment
    ) -> Update<AddressBookModel> {
        switch action {
            
        case .present(let isPresented):
            return present(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
            
        case .refreshDid:
            let fx: Fx<AddressBookAction> = environment.noosphere
                .identityPublisher()
                .tryMap({ identity in
                    let did = try Did(identity).unwrap()
                    return AddressBookAction.succeedRefreshDid(did)
                })
                .recover({error in
                    AddressBookAction.failRefreshDid(error.localizedDescription)
                })
                .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
            
        case .succeedRefreshDid(let did):
            var model = state
            model.did = did
            return Update(state: model)
            
        case .failRefreshDid(let error):
            environment.logger.log("Failed to refresh sphere did: \(error)")
            return Update(state: state)
            
        case .refreshEntries(let forceRefreshFromNoosphere):
            let fx: Fx<AddressBookAction> =
            environment.addressBook
                .listEntriesPublisher(refetch: forceRefreshFromNoosphere)
                .map({ follows in
                    AddressBookAction.populate(follows)
                })
                .recover({ error in
                    AddressBookAction.failRefreshEntries(
                        error.localizedDescription
                    )
                })
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)

        case .failRefreshEntries(let error):
            environment.logger.log("Failed to refresh entries: \(error)")
            return Update(state: state)
            
        case .populate(let follows):
            var model = state
            model.follows = follows
            return Update(state: model)
            
        case .presentFollowUserForm(let isPresented):
            var model = state
            
            model.failFollowErrorMessage = nil
            model.isFollowUserFormPresented = isPresented
            
            return update(
                state: model,
                actions: [
                    .followUserForm(.didField(.reset)),
                    .followUserForm(.petnameField(.reset))
                ],
                environment: environment
            )
            
        case .followUserForm(let action):
            return FollowUserFormCursor_old.update(
                state: state,
                action: action,
                environment: ()
            )
            
        case .requestFollow:
            return update(
                state: state,
                actions: [
                    // Show errors on any untouched fields, hints at why you cannot submit
                    .followUserForm(.didField(.markAsTouched)),
                    .followUserForm(.petnameField(.markAsTouched)),
                    .attemptFollow
                ],
                environment: environment
            )
            
            
        case .attemptFollow:
            guard let did = state.followUserForm.did.validated else {
                return Update(state: state)
            }
            guard let petname = state.followUserForm.petname.validated else {
                return Update(state: state)
            }
            
            guard !state.follows.contains(where: { f in f.did == did }) else {
                return update(
                    state: state,
                    action: .failFollow(error: AddressBookError.alreadyFollowing.localizedDescription),
                    environment: environment
                )
            }
            
            let fx: Fx<AddressBookAction> =
            environment.addressBook
                .followUserPublisher(did: did, petname: petname)
                .map({ _ in
                    AddressBookAction.succeedFollow(did: did, petname: petname)
                })
                .recover({ error in
                    AddressBookAction.failFollow(error: error.localizedDescription)
                })
                .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
            
        case .succeedFollow(did: let did, petname: let petname):
            let entry = AddressBookEntry(petname: petname, did: did)
            
            var model = state
            model.isFollowUserFormPresented = false
            model.follows.append(entry)
            
            return update(
                state: model,
                action: .refreshEntries(forceRefetchFromNoosphere: true),
                environment: environment
            )
            
        case .failFollow(error: let error):
            var model = state
            model.failFollowErrorMessage = error
            return Update(state: model)
            
        case .dismissFailFollowError:
            var model = state
            model.failFollowErrorMessage = nil
            return Update(state: model)
            
        case .requestUnfollow(petname: let petname):
            var model = state
            model.unfollowCandidate = petname
            return Update(state: model)
            
        case .cancelUnfollow:
            var model = state
            model.unfollowCandidate = nil
            return Update(state: model)
            
        case .confirmUnfollow:
            guard let petname = state.unfollowCandidate else {
                return Update(state: state)
            }
            
            let fx: Fx<AddressBookAction> = environment.addressBook
                .unfollowUserPublisher(petname: petname)
                .map({ _ in
                    AddressBookAction.succeedUnfollow(petname: petname)
                })
                .recover({ error in
                    AddressBookAction.failUnfollow(error: error.localizedDescription)
                })
                .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
            
        case .succeedUnfollow(let petname):
            var model = state
            model.follows.removeAll { f in
                f.petname == petname
            }
            return update(
                state: model,
                action: .refreshEntries(forceRefetchFromNoosphere: true),
                environment: environment
            )
            
        case .failUnfollow(error: let error):
            var model = state
            model.failUnfollowErrorMessage = error
            return Update(state: model)
            
        case .dismissFailUnfollowError:
            var model = state
            model.failUnfollowErrorMessage = nil
            return Update(state: model)
            
        case .presentQRCodeScanner(let isPresented):
            var model = state
            model.failQRCodeScanErrorMessage = nil
            model.isQrCodeScannerPresented = isPresented
            return Update(state: model)
            
        case .qrCodeScanned(scannedContent: let content):
            return update(
                state: state,
                actions: [
                    .followUserForm(.didField(.markAsTouched)),
                    .followUserForm(.didField(.setValue(input: content)))
                ],
                environment: environment
            )
            
        case .qrCodeScanError(error: let error):
            var model = state
            model.failQRCodeScanErrorMessage = error
            return Update(state: model)
        }
    }
    
    static func present(
        state: Self,
        environment: Self.Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isPresented = isPresented
        model.failUnfollowErrorMessage = nil
        model.failFollowErrorMessage = nil
        
        guard isPresented else {
            return update(
                state: model,
                action: .refreshEntries(forceRefetchFromNoosphere: false),
                environment: environment
            )
        }

        return update(
            state: model,
            actions: [
                .refreshDid,
                .refreshEntries(forceRefetchFromNoosphere: false)
            ],
            environment: environment
        )
    }
}
