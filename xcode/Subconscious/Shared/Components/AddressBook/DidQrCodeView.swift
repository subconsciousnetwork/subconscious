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
    var color: Color
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    let colorInvertFilter = CIFilter.colorInvert()
    let maskFilter = CIFilter.blendWithMask()
    
    func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)
        
        colorInvertFilter.inputImage = filter.outputImage
        guard let inverted = colorInvertFilter.outputImage else { return nil }
        
        maskFilter.maskImage = inverted
        // This is the only way I managed to produce a CIColor from .accentColor
        // https://developer.apple.com/forums/thread/687764
        // https://stackoverflow.com/questions/56586055/how-to-get-rgb-components-from-color-in-swiftui
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let col = CIColor(red: r, green: g, blue: b, alpha: a)
        maskFilter.inputImage = CIImage(color: col)
        
        guard let img = maskFilter.outputImage else { return nil }
        guard let cgImg = context.createCGImage(img, from: img.extent) else { return nil }
        
        return UIImage(cgImage: cgImg)
    }
    
    
    var body: some View {
        let img = generateQRCode(from: "\(did.did)") ?? UIImage(systemName: "xmark.circle") ?? UIImage()
        
        Image(uiImage: img)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .padding(AppTheme.unit2)
    }
}


struct DidQrCodeView_Previews: PreviewProvider {
    static var previews: some View {
        DidQrCodeView(
            did: Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!,
            color: .accentColor
        )
    }
}
