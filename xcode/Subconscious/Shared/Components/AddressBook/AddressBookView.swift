//
//  AddressBookView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import os
import SwiftUI
import ObservableStore

struct AddressBookView: View {
    var state: AddressBookModel
    var send: (AddressBookAction) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                if (state.follows.count == 0) {
                    VStack(spacing: AppTheme.unit2) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.secondary)
                        Text("You're not following anyone... yet!")
                            .foregroundColor(.secondary)
                    }
                    .padding(AppTheme.unit2)
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Section(header: Text("Following")) {
                        List {
                            ForEach(state.follows, id: \.did) { user in
                                AddressBookEntryView(
                                    pfp: user.pfp,
                                    petname: user.petname,
                                    did: user.did
                                )
                                .frame(maxWidth: .infinity)
                                .swipeActions {
                                    Button("Unfollow") {
                                        send(.requestUnfollow(petname: user.petname))
                                    }
                                }
                            }
                        }
                    }
                }
                // Basic error visibility
                if let msg = state.failUnfollowErrorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .frame(width: 24, height: 22)
                            .padding(.horizontal, 8)
                            .foregroundColor(.red)
                            .background(Color.clear)
                        Text(msg)
                            .foregroundColor(.red)
                    }
                }
                
                if let did = state.did {
                    Section(header: Text("My DID")) {
                        DidView(did: did)
                    }
                }
            }
            .navigationTitle("Address Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", role: .cancel) {
                        AddressBookModel.logger.debug("Close Address Book")
                        send(.present(false))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        action: {
                            send(.presentFollowUserForm(true))
                        },
                        label: {
                            Image(systemName: "person.badge.plus")
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(
                isPresented: Binding(
                    get: { state.isFollowUserFormPresented },
                    send: send,
                    tag: AddressBookAction.presentFollowUserForm
                )
            ) {
                FollowUserView(state: state, send: send)
            }
        }
    }
}

struct AddressBook_Previews: PreviewProvider {
    static var previews: some View {
        AddressBookView(
            state: AddressBookModel(
                follows: [
                    AddressBookEntry(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did(  "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!),
                    AddressBookEntry(pfp: Image("sub_logo_light"), petname: Petname("bob")!, did: Did("did:key:z6MkmBJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!),
                    AddressBookEntry(pfp: Image("sub_logo_dark"), petname: Petname("alice")!, did: Did("did:key:z6MjmBJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!)
                ],
                isFollowUserFormPresented: false // Toggle to test sheet
            ),
            send: { action in }
        )
    }
}
