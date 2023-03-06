//
//  AddFriendViaQRCodeView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 6/3/2023.
//

import Foundation
import SwiftUI
import CodeScanner

struct AddFriendViaQRCodeView: View {
    var onScannedDid: (String) -> Void
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        CodeScannerView(
            codeTypes: [.qr],
            simulatedData: "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7"
        ) { res in
            switch res {
            case .success(let result):
                print("Found code: \(result.string)")
                onScannedDid(result.string)
            case .failure(let error):
                print(error.localizedDescription)
            }
            
            presentationMode.wrappedValue.dismiss()
        }
    }
}
