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
                                    Button("Unfollow", role: .destructive) {
                                        send(.unfollow(did: user.did))
                                    }
                                }
                            }
                        }
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
                    Button("Close") {
                        AddressBookModel.logger.debug("Close Address Book")
                        send(.present(false))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink(
                        destination: {
                            FollowUserView(state: state, send: send)
                        },
                        label: {
                            Image(systemName: "person.badge.plus")
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AddressBook_Previews: PreviewProvider {
    struct TestView: View {
        @StateObject private var store = Store(
            state: AddressBookModel(
                follows: [
                    AddressBookEntry(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did(  "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!),
                    AddressBookEntry(pfp: Image("sub_logo_light"), petname: Petname("bob")!, did: Did("did:key:z6MkmBJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!),
                    AddressBookEntry(pfp: Image("sub_logo_dark"), petname: Petname("alice")!, did: Did("did:key:z6MjmBJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!)
                ]
            ),
            action: .present(true),
            environment: AddressBookEnvironment(noosphere: PlaceholderSphereIdentityProvider())
        )

        var body: some View {
            AddressBookView(
                state: store.state,
                send: store.send
            )
        }
    }

    static var previews: some View {
        TestView()
    }
}