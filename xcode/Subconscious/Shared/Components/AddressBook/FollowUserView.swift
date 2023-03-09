//
//  FollowUserView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import SwiftUI
import ObservableStore

struct FollowUserView: View {
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
                Section(header: Text("User To Follow")) {
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
            .navigationTitle("Follow User")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        guard let did = validateDid(key: did) else {
                            return
                        }
                        
                        guard let petname = validatePetname(petname: petname) else {
                            return
                        }
                        
                        send(.requestFollow(did: did, petname: petname))
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FollowUserView_Previews: PreviewProvider {
    static var previews: some View {
        FollowUserView(
            state: AddressBookModel(),
            send: { action in }
        )
    }
}
