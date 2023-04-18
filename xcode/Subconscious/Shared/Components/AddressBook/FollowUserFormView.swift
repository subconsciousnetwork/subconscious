//
//  FollowUserFormView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import SwiftUI
import ObservableStore
import CodeScanner

struct FollowUserFormView: View {
    var state: FollowUserFormModel
    var send: (FollowUserFormAction) -> Void
    
    var body: some View {
        Section(header: Text("User To Follow")) {
            HStack(alignment: .top) {
                Image(systemName: "key")
                    .foregroundColor(.accentColor)
                ValidatedTextField(
                    placeholder: "DID",
                    text: Binding(
                        get: { state.did.value },
                        send: send,
                        tag: { v in .didField(.setValue(input: v))}
                    ),
                    onFocusChanged: { focused in
                        send(.didField(.focusChange(focused: focused)))
                    },
                    caption: "e.g. did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                    hasError: state.did.hasError
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
                        get: { state.petname.value },
                        send: send,
                        tag: { v in .petnameField(.setValue(input: v))}
                    ),
                    onFocusChanged: { focused in
                        send(.petnameField(.focusChange(focused: focused)))
                    },
                    caption: "Lowercase letters, numbers and dashes only.",
                    hasError: state.petname.hasError
                )
                .formField()
                .lineLimit(1)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            }
        }
    }
}

struct FollowUserView: View {
    var state: AddressBookModel
    var form: FollowUserFormModel {
        get { state.followUserForm }
    }
    var send: (AddressBookAction) -> Void
    
    func onQRCodeScanResult(res: Result<ScanResult, ScanError>) {
        switch res {
        case .success(let result):
            send(.qrCodeScanned(scannedContent: result.string))
        case .failure(let error):
            send(.qrCodeScanError(error: error.localizedDescription))
        }
    }
    
    var body: some View {
            VStack {
                Form {
                    FollowUserFormView(
                        state: state.followUserForm,
                        send: Address.forward(send: send, tag: FollowUserFormCursor.tag)
                    )
                    
                    if Config.default.addByQRCode {
                        Section(header: Text("Add via QR Code")) {
                            Button(
                                action: {
                                    send(.presentQRCodeScanner(true))
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
            .fullScreenCover(
                isPresented: Binding(
                    get: { state.isQrCodeScannerPresented && Config.default.addByQRCode },
                    send: send,
                    tag: AddressBookAction.presentQRCodeScanner
                )
            ) {
                FollowUserViaQRCodeView(
                    onScanResult: onQRCodeScanResult,
                    onCancel: { send(.presentQRCodeScanner(false)) },
                    errorMessage: state.failQRCodeScanErrorMessage
                )
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
