//
//  AddFriendView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import SwiftUI
import ObservableStore

struct AddFriendView: View {
    var state: AddressBookModel
    var send: (AddressBookAction) -> Void
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var did: String = ""
    @State var petname: String = ""
    
    func validateDid(key: String) -> Did? {
        Did(key)
    }
    
    func validatePetname(petname: String) -> Petname? {
        Petname(petname)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Friend Details")) {
                    HStack(alignment: .top) {
                        Image(systemName: "key")
                            .foregroundColor(.accentColor)
                        ValidatedTextField(
                            placeholder: "DID",
                            text: $did,
                            caption: "e.g. did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                            isValid: validateDid(key: did) != nil || did.count  == 0 // Prevent initial error
                        )
                        .lineLimit(1)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "at")
                            .foregroundColor(.accentColor)
                        ValidatedTextField(
                            placeholder: "Petname",
                            text: $petname,
                            caption: "Lowercase letters, numbers and dashes only.",
                            isValid: validatePetname(petname: petname) != nil || petname.count == 0
                        )
                        .lineLimit(1)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    }
                }
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let did = validateDid(key: did) {
                            if let petname = validatePetname(petname: petname) {
                                send(.addFriend(did: did, petname: petname))
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {
    struct TestView: View {
        @StateObject private var store = Store(
            state: AddressBookModel(),
            environment: AddressBookEnvironment(noosphere: PlaceholderSphereIdentityProvider())
        )

        var body: some View {
            AddFriendView(
                state: store.state,
                send: store.send
            )
        }
    }

    static var previews: some View {
        TestView()
    }
}
