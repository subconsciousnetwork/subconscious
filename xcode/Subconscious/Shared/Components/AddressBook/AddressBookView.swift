//
//  AddressBookView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import SwiftUI
import ObservableStore

struct AddressBookEntry {
    var pfp: Image
    var petname: String
    var did: String
}

struct AddressBookView: View {
    @ObservedObject var app: Store<AppModel>
    var unknown = "Unknown"
    
    // Temp state, will be moved to slice of AppStore later
    @State var didCopy = false
    
    // Temp state, will be moved to slice of AppStore later
    @State var following: [AddressBookEntry] = [
        AddressBookEntry(pfp: Image("pfp-dog"), petname: "ben", did: "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"),
        AddressBookEntry(pfp: Image("sub_logo_light"), petname: "bob", did: "did:key:z6MkmBJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")
    ]
    
    var myDid = "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
    
    func delete(at offsets: IndexSet) {
        following.remove(atOffsets: offsets)
    }

    var body: some View {
        NavigationStack {
            Form {
                if (following.count == 0) {
                    Text("No friends?")
                } else {
                    Section(header: Text("Friends")) {
                        List {
                            ForEach(following, id: \.did) { user in
                                AddressBookEntryView(pfp: user.pfp, petname: user.petname,
                                                     did: user.did)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
                Section(header: Text("My Details")) {
                   DidQrCodeView(did: myDid)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                    
                    VStack {
                        
                        HStack{
                        Text(myDid)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                // TODO: actually copy it!
                                didCopy = true
                            }, label: {
                                if !didCopy {
                                    HStack {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .transition(
                                        .asymmetric(
                                            insertion: .identity,
                                            removal: .move(
                                                edge: .top
                                            ).combined(
                                                with: .opacity
                                            )
                                        )
                                    )
                                } else {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                    }
                                    .transition(.opacity)
                                }
                            })
                        }
                    }
                }
                
            }
            .navigationTitle("Address Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        app.send(.presentSettingsSheet(false))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink(
                        destination: {
                            AddFriendView(app: app)
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
    static var previews: some View {
        AddressBookView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
