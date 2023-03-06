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
    var environment: AddressBookEnvironment
    var send: (AddressBookAction) -> Void
    
    var myDid: Did? {
        get {
            do {
                return try Did(environment.noosphere.identity())
            } catch {
                return nil
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        guard let idx = offsets.first else {
            return
        }
        
        if let f = state.follows.get(idx) {
            send(.removeFriend(did: f.did))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if (state.follows.count == 0) {
                    VStack(spacing: AppTheme.unit2) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.secondary)
                        Text("No friends yet, try adding one!")
                            .foregroundColor(.secondary)
                    }
                    .padding(AppTheme.unit2)
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Section(header: Text("Friends")) {
                        List {
                            ForEach(state.follows, id: \.did) { user in
                                AddressBookEntryView(
                                    pfp: user.pfp,
                                    petname: user.petname,
                                    did: user.did
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
                if let myDid = myDid {
                    Section(header: Text("My DID")) {
                        MyDidView(myDid: myDid)
                    }
                }
                
            }
            .navigationTitle("Address Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        AddressBookModel.logger.debug("Close Address Book")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink(
                        destination: {
                            AddFriendView(state: state, send: send)
                        },
                        label: {
                    Text("Add Friend")
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
            environment: AddressBookEnvironment(noosphere: PlaceholderSphereIdentityProvider())
        )

        var body: some View {
            AddressBookView(
                state: store.state,
                environment: store.environment,
                send: store.send
            )
        }
    }

    static var previews: some View {
        TestView()
    }
}
