//
//  DidQrCodeView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/2/2023.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

struct DidQrCodeView: View {
    var did: Did
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    // Probably best to extract this logic somewhere common
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        // Appears we can style / customise this quite a lot, but might require digging into CoreImage internals. This libray might be useful: https://github.com/dagronf/QRCode

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    var body: some View {
        Image(uiImage: generateQRCode(from: "\(did)"))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .padding(AppTheme.unit2)
    }
}


struct DidQrCodeView_Previews: PreviewProvider {
    static var previews: some View {
        DidQrCodeView(
            did: Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!
        )
    }
}
