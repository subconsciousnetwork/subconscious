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
    @Environment(\.dismiss) var dismiss
    
    var onScannedDid: (String) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack {
            // Toolbar is unavailable here, create a minimal one that blends with notch/bezel.
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .buttonStyle(.borderless)

                Spacer()
            }
            .padding(AppTheme.unit2)
            .background(Color.black)
            
            CodeScannerView(
                codeTypes: [.qr],
                showViewfinder: true,
                simulatedData: "did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7",
                shouldVibrateOnSuccess: true
            ) { res in
                switch res {
                case .success(let result):
                    print("Found code: \(result.string)")
                    onScannedDid(result.string)
                case .failure(let error):
                    print(error.localizedDescription)
                }
                
                dismiss()
            }
        }
    }
}
