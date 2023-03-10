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
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("User To Follow")) {
                    HStack(alignment: .top) {
                        Image(systemName: "key")
                            .foregroundColor(.accentColor)
                        ValidatedTextField(
                            placeholder: "DID",
                            text: Binding(
                                get: { state.followUserForm.did.value },
                                send: send,
                                tag: AddressBookAction.setDidField
                            ),
                            caption: "e.g. did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                            isValid: state.followUserForm.did.isValid
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
                            text: Binding(
                                get: { state.followUserForm.petname.value },
                                send: send,
                                tag: AddressBookAction.setPetnameField
                            ),
                            caption: "Lowercase letters, numbers and dashes only.",
                            isValid: state.followUserForm.petname.isValid
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
                        send(.requestFollow)
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
