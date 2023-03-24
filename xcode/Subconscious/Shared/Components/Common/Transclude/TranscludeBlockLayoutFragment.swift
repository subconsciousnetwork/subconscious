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

import os
import SwiftUI

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoreGraphics

struct EmbeddedTranscludePreview: View {
    var address: MemoAddress
    var excerpt: String
    
    var body: some View {
        Transclude2View(address: address, excerpt: excerpt, action: {})
            .padding(1)
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
    static var logger = Logger(
        subsystem: Config.default.rdns,
        category: "editor"
    )

    var height: CGFloat? = 0.0
    var width: CGFloat? = 0.0
    
    var slashlink: Slashlink?
    var entry: EntryStub?
    
    var hosted: UIHostingController<EmbeddedTranscludePreview>?
    
    override var leadingPadding: CGFloat { return 0 }
    override var trailingPadding: CGFloat { return 0 }
    override var topMargin: CGFloat { return 0 }
    override var bottomMargin: CGFloat { return 0 }
    
    func prepare(textContainer: NSTextContainer) {
        guard let slashlink = slashlink else {
            TranscludeBlockLayoutFragment.logger.warning("nil slashlink provided to transclude block")
            return
        }
        
        guard let entry = entry else {
            TranscludeBlockLayoutFragment.logger.warning("nil entry provided to transclude block")
            return
        }
        
        let v = EmbeddedTranscludePreview(
            address: MemoAddress.public(slashlink),
            excerpt: entry.excerpt
        )
        
        // Host our SwiftUI view within a UIKit view
        self.hosted = UIHostingController(rootView: v)
        guard let hosted = hosted else {
            return
        }
        guard let view = hosted.view else {
            return
        }
        
        let width = textContainer.size.width
        
        view.backgroundColor = .clear
        mountSubview(view: view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // First, we try and render the view at zero size
        do {
            let fit = hosted.sizeThatFits(in: CGSize(width: width, height: 0))
            view.frame = CGRect(origin: CGPoint(x: 0, y: fit.height), size: CGSize(width: 0, height: fit.height))
            view.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: fit.height))
        }
        
        let HEIGHT_CONSTRAINT = 128.0
        
        // Re-layout at the frame size. Now, magically, the fit will return the minimum height needed to fit the view.
        let fit = hosted.sizeThatFits(in: CGSize(width: width, height: HEIGHT_CONSTRAINT))
        view.frame = CGRect(origin: CGPoint(x: 0, y: fit.height), size: CGSize(width: 0, height: fit.height))
        view.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: fit.height))
        
        TranscludeBlockLayoutFragment.logger.debug("Calculated height: \(fit.height)")
        self.height = fit.height
        self.width = width
        
        unmountSubview()
    }
    
    private func unmountSubview() {
        guard let view = hosted?.view else {
            return
        }
        
        view.removeFromSuperview()
    }
    
    private func mountSubview(view: UIView) {
        // We have to mount the view before it will actually do layout calculations
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            TranscludeBlockLayoutFragment.logger.warning("Could not find UIWindowScene")
            return
        }
        
        guard let rootView = scene.windows.first?.rootViewController?.view else {
            TranscludeBlockLayoutFragment.logger.warning("Could not find rootViewController")
            return
        }
        
        rootView.addSubview(view)
    }
    
    private func render() -> UIImage? {
        let height = height ?? 0.0
        let width = width ?? 0.0
        
        guard let view = hosted?.view else {
            return nil
        }
        
        mountSubview(view: view)
        
        view.frame = CGRect(origin: CGPoint(x: 0, y: height), size: CGSize(width: 0, height: height))
        view.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: height))
        
        let img = view.asImage()
        unmountSubview()
        
        // Cache for reuse in layout calculations
        return img
    }
    
    // Determines how this flows around text
    override var layoutFragmentFrame: CGRect {
        let parent = super.layoutFragmentFrame
        let h = height ?? 0.0
        let r = CGRect(origin: parent.origin, size: CGSize(width: parent.width, height: parent.height + h))
        return r
    }
    
    // Determines the full drawing bounds, should be larger than layoutFragmentFrame
    override var renderingSurfaceBounds: CGRect {
        let w = width ?? 0.0
        let h = height ?? 0.0
        
        let size = super.renderingSurfaceBounds.union(CGRect(x: 0, y: 0, width: w, height: h))
        return size
    }
    
    private func withTranslation(x: CGFloat, y: CGFloat, ctx: CGContext, perform: (CGContext) -> Void) {
        ctx.translateBy(x: x, y: y)
        perform(ctx)
        ctx.translateBy(x: -x, y: -y)
    }
    
    override func draw(at renderingOrigin: CGPoint, in ctx: CGContext) {
        guard let img = render() else {
            return super.draw(at: renderingOrigin, in: ctx)
        }
        
        ctx.saveGState()
        
        let height = img.size.height
        withTranslation(x: leadingPadding, y: super.layoutFragmentFrame.height, ctx: ctx) { ctx in
            ctx.draw(img.cgImage!, in: CGRect(x: 0, y: 0, width: img.size.width, height: height))
            // DEBUG: Render border around the cached view image
//                ctx.stroke(CGRect(origin: renderingSurfaceBounds.origin, size: img.size))
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
