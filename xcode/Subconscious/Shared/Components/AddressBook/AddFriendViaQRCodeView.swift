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
    
    var onScanResult: (Result<ScanResult, ScanError>) -> Void
    var onCancel: () -> Void
    var errorMessage: String?
    
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
                onScanResult(res)
                dismiss()
            }
        }
        .alert(
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in }
            )
        ) {
            let errorMessage = errorMessage ?? "Failed to scan"
            
            return Alert(
                title: Text("QR Code Error"),
                message: Text(errorMessage)
            )
        }
    }
}
