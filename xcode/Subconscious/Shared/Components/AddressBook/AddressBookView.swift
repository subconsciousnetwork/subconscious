//
//  AddressBookView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import os
import SwiftUI
import ObservableStore

struct AddressBookEntry: Equatable {
    var pfp: Image
    var petname: Petname
    var did: Did
}

struct AddressBookEnvironment { }

enum AddressBookAction: Hashable {
    case addFriend(did: Did, petname: Petname)
    case removeFriend(did: Did)
}

struct AddressBookModel: ModelProtocol {
    var friends: [AddressBookEntry] = []

    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AddressBookModel"
    )

    static func update(
        state: AddressBookModel,
        action: AddressBookAction,
        environment: AddressBookEnvironment
    ) -> Update<AddressBookModel> {
        switch action {
        case .addFriend(did: let did, petname: let petname):
            // Guard against duplicates
            guard !state.friends.contains(where: { entry in entry.did == did }) else {
                return Update(state: state)
            }
            
            let entry = AddressBookEntry(pfp: Image("pfp-dog"), petname: petname, did: did)
            
            var model = state
            model.friends.append(entry)
            return Update(state: model)
        case .removeFriend(did: let did):
            var model = state
            
            model.friends.removeAll { entry in
                entry.did == did
            }
            return Update(state: model)
        }
    }
}

struct AddressBookView: View {
    var state: AddressBookModel
    var send: (AddressBookAction) -> Void
    
    // TODO: how can I actually get this information?
    var myDid = Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!
    
    func delete(at offsets: IndexSet) {
        guard let idx = offsets.first else {
            return
        }
        
        if let f = state.friends.get(idx) {
            send(.removeFriend(did: f.did))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if (state.friends.count == 0) {
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
                            ForEach(state.friends, id: \.did) { user in
                                AddressBookEntryView(pfp: user.pfp, petname: user.petname,
                                                     did: user.did)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
                Section(header: Text("My DID")) {
                    MyDidView(myDid: myDid)
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
                friends: [
                    AddressBookEntry(pfp: Image("pfp-dog"), petname: Petname("ben")!, did: Did(  "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!),
                    AddressBookEntry(pfp: Image("sub_logo_light"), petname: Petname("bob")!, did: Did("did:key:z6MkmBJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!),
                    AddressBookEntry(pfp: Image("sub_logo_dark"), petname: Petname("alice")!, did: Did("did:key:z6MjmBJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!)
                ]
            ),
            environment: AddressBookEnvironment()
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
