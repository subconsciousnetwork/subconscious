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
    var form: FollowUserFormModel {
        get { state.followUserForm }
    }
    var send: (AddressBookAction) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("User To Follow")) {
                        HStack(alignment: .top) {
                            Image(systemName: "key")
                                .foregroundColor(.accentColor)
                            ValidatedTextField(
                                placeholder: "DID",
                                text: Binding(
                                    get: { form.did.value },
                                    send: send,
                                    tag: { v in .didField(.setValue(input: v))}
                                ),
                                onFocusChanged: { focused in
                                    send(.didField(.focusChange(focused: focused)))
                                },
                                caption: "e.g. did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                                hasError: form.did.hasError
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
                                    get: { form.petname.value },
                                    send: send,
                                    tag: { v in .petnameField(.setValue(input: v))}
                                ),
                                onFocusChanged: { focused in
                                    send(.petnameField(.focusChange(focused: focused)))
                                },
                                caption: "Lowercase letters, numbers and dashes only.",
                                hasError: form.petname.hasError
                            )
                            .lineLimit(1)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        }
                    }
                    
                    if let msg = state.failFollowErrorMessage {
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
                }
            }
            .navigationTitle("Follow User")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        send(.requestFollow)
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button("Cancel") {
                        send(.presentFollowUserForm(false))
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
