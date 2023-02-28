//
//  TranscludeBlockLayoutFragment.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/2/2023.
//

/*
 Copyright © 2022 Apple Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import SwiftUI

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoreGraphics

struct EmbeddedTranscludePreview: View {
    var label: String = "Subconscious"
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("title")
            Text(label)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: 128) // TODO: share constant for all instances of 128
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(.purple, lineWidth: 2)
            )
        .padding(2)
    }
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let img = renderer.image { rendererContext in
            rendererContext.cgContext.saveGState()
            
            // SwiftUI views render upside down by default, flip them
            let flipVertical: CGAffineTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: bounds.height )
            rendererContext.cgContext.concatenate(flipVertical)
            
            layer.render(in: rendererContext.cgContext)
            
            rendererContext.cgContext.restoreGState()
        }
        
        return img
    }
}

class TranscludeBlockLayoutFragment: NSTextLayoutFragment {
    // Max height constraint
    let SLASHLINK_PREVIEW_HEIGHT = 128.0
    var text: String?
    
    override var leadingPadding: CGFloat { return 10 }
    override var trailingPadding: CGFloat { return 10 }
    override var topMargin: CGFloat { return 0 }
    override var bottomMargin: CGFloat { return 0 }
    
    private var img: UIImage?
    
    private func render() {
        let v = EmbeddedTranscludePreview(label: text ?? "Testing")
        // Host our SwiftUI view within a UIKit view
        let hosted = UIHostingController(rootView: v)
        let view = hosted.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // We have to mount the view before it will actually do layout calculations
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(hosted.view)
        
        // Ideally here is where we would dynamically adjust the height of the rendered card
        // However there doesn't seem to be a way to get the "preferred" size of the child content, it always tries to expand to fill the space provided
        // This might be due to the underlying UIKit constraint system
        let size = hosted.sizeThatFits(in: CGSize(width: containerWidth(), height: SLASHLINK_PREVIEW_HEIGHT))
        hosted.view.frame = CGRect(origin: CGPoint(x: 0, y: SLASHLINK_PREVIEW_HEIGHT), size: CGSize(width: containerWidth(), height: size.height))
        hosted.view.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: containerWidth(), height: size.height ))
        hosted.view.backgroundColor = .clear
        
        let img = view.asImage()
        hosted.view.removeFromSuperview()
        
        // Cache for reuse in layout calculations
        self.img = img
        
        // Reflow the document layout to include the subview dimensions
        invalidateLayout()
    }
    
    private func containerWidth() -> CGFloat {
        return self.textLayoutManager!.textContainer!.size.width - leadingPadding - trailingPadding
    }
    
    // Determines how this flows around text
    override var layoutFragmentFrame: CGRect {
        let parent = super.layoutFragmentFrame
        let r = CGRect(origin: parent.origin, size: CGSize(width: parent.width, height: parent.height + (self.img?.size.height ?? 0)))
        return r
    }
    
    // Determines the full drawing bounds, should be larger than layoutFragmentFrame
    override var renderingSurfaceBounds: CGRect {
        let w = containerWidth()
        
        let size = super.renderingSurfaceBounds.union(CGRect(x: 0, y: 0, width: w, height: SLASHLINK_PREVIEW_HEIGHT))
        return size
    }
    
    private func withTranslation(x: CGFloat, y: CGFloat, ctx: CGContext, perform: (CGContext) -> Void) {
        ctx.translateBy(x: x, y: y)
        perform(ctx)
        ctx.translateBy(x: -x, y: -y)
    }
    
    override func draw(at renderingOrigin: CGPoint, in ctx: CGContext) {
        render()
        ctx.saveGState()
        
        if let img = self.img {
            let height = img.size.height
            withTranslation(x: leadingPadding, y: super.layoutFragmentFrame.height, ctx: ctx) { ctx in
                ctx.draw(img.cgImage!, in: CGRect(x: 0, y: 0, width: img.size.width, height: height))
                // DEBUG: Render border around the cached view image
//                ctx.stroke(CGRect(origin: renderingSurfaceBounds.origin, size: img.size))
            }
        }
        
        // DEBUG: render border around entire draw surface
//        withTranslation(x: leadingPadding, y: 0, ctx: ctx) { ctx in
//            ctx.stroke(CGRect(origin: renderingSurfaceBounds.origin, size: renderingSurfaceBounds.size))
//        }
        
        ctx.restoreGState()
        
        // Draw the text on top.
        super.draw(at: renderingOrigin, in: ctx)
    }
}
