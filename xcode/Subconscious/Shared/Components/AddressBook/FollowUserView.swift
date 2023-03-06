//
//  FollowUserView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import SwiftUI
import ObservableStore
import CodeScanner

typealias Validator<I, O> = (I) -> O?

struct FormField<I, O> {
    var value: I
    var validate: Validator<I, O>
    var touched: Bool = false
    
    var isValid: Bool {
        get {
            validate(value) != nil
        }
    }
    var hasError: Bool {
        get {
            validate(value) == nil && touched
        }
    }
}

struct FollowUserView: View {
    var state: AddressBookModel
    var form: FollowUserFormModel {
        get { state.followUserForm }
    }
    var send: (AddressBookAction) -> Void
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var did: FormField<String, Did> = FormField(value: "", validate: Self.validateDid)
    @State var petname: FormField<String, Petname> = FormField(value: "", validate: Self.validatePetname)
    
    static func validateDid(key: String) -> Did? {
        Did(key)
    }
    
    static func validatePetname(petname: String) -> Petname? {
        Petname(petname)
    }
    
    func populateDidFromQRCodeResult(encodedText: String) {
        did.value = encodedText
    }
    
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
                            .formField()
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
                            .formField()
                            .lineLimit(1)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        }
                    }
                }
                
                Section(header: Text("Add via QR Code")) {
                    NavigationLink(
                        destination: {
                            AddFriendViaQRCodeView(onScannedDid: populateDidFromQRCodeResult)
                        },
                        label: {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("Scan Code")
                            }
                            .foregroundColor(.accentColor)
                        }
                    )
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
                    Button("Cancel", role: .cancel) {
                        send(.presentFollowUserForm(false))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                isPresented: Binding(
                    get: { state.failFollowErrorMessage != nil },
                    set: { _ in send(.dismissFailFollowError) }
                )
            ) {
                Alert(
                    title: Text("Failed to Follow User"),
                    message: Text(state.failFollowErrorMessage ?? "An unknown error ocurred")
                )
            }
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
