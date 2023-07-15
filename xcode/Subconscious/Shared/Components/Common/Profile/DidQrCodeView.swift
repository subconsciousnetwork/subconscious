//
//  DidQrCodeView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/2/2023.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

extension DidQrCodeView {
    static func generate(from did: String, color: Color) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let colorInvertFilter = CIFilter.colorInvert()
        let maskFilter = CIFilter.blendWithMask()
        
        let fallback = UIImage(systemName: "xmark.circle") ?? UIImage()
        
        filter.message = Data(did.utf8)
        
        colorInvertFilter.inputImage = filter.outputImage
        guard let inverted = colorInvertFilter.outputImage else {
            return fallback
        }
        
        maskFilter.maskImage = inverted
        // This is the only way I managed to produce a CIColor from a SwiftUI.Color
        // https://developer.apple.com/forums/thread/687764
        // https://stackoverflow.com/questions/56586055/how-to-get-rgb-components-from-color-in-swiftui
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let col = CIColor(red: r, green: g, blue: b, alpha: a)
        maskFilter.inputImage = CIImage(color: col)
        
        guard let img = maskFilter.outputImage else {
            return fallback
        }
        
        let scaleFactor = 10.0
        let upscaleImg = img
            .samplingNearest()
            .transformed(
                by: CGAffineTransformMakeScale(scaleFactor, scaleFactor)
            )
        
        guard let cgImg = context.createCGImage(
            upscaleImg,
            from: upscaleImg.extent
        ) else {
            return fallback
        }
        
        return UIImage(cgImage: cgImg)
    }
}

struct DidQrCodeView: View {
    var did: Did
    var color: Color
    
    var img: UIImage {
        Self.generate(from: did.did, color: color)
    }
    
    var body: some View {
        DidQrCodeImage(image: img)
    }
}

struct DidQrCodeImage: View {
    var image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .padding(AppTheme.unit2)
    }
}

struct ShareableDidQrCodeView: View {
    var did: Did
    var color: Color
    
    var img: UIImage {
        DidQrCodeView.generate(from: did.did, color: color)
    }
    
    var body: some View {
        let shareable = Image(uiImage: img)
        
        ShareLink(
            item: shareable,
            preview: SharePreview(
                "Your QR Code",
                image: shareable
            )
        ) {
            HStack(alignment: .center) {
                DidQrCodeImage(image: img)
                Spacer(minLength: AppTheme.unit2)
                Image(systemName: "square.and.arrow.up")
            }
        }
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
