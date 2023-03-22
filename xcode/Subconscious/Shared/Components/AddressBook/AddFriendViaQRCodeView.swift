//
//  AddFriendViaQRCodeView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 6/3/2023.
//

import Foundation
import SwiftUI
import CodeScanner
import os

struct AddFriendViaQRCodeView: View {
    @Environment(\.dismiss) var dismiss
    
    var onScannedDid: (String) -> Void
    var onCancel: () -> Void
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "AddFriendViaQRCodeView"
    )
    
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
                simulatedData: Config.default.fallbackSimulatorQrCodeScanResult,
                shouldVibrateOnSuccess: true
            ) { res in
                switch res {
                case .success(let result):
                    AddFriendViaQRCodeView.logger.debug("Found code: \(result.string)")
                    onScannedDid(result.string)
                case .failure(let error):
                    AddFriendViaQRCodeView.logger.debug("\(error.localizedDescription)")
                }
                
                dismiss()
            }
        }
    }
}
