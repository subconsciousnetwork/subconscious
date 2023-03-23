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
    static var logger = Logger(
        subsystem: Config.default.rdns,
        category: "editor"
    )

    // Max height constraint
    let SLASHLINK_PREVIEW_HEIGHT = 128.0
    var text: String?
    var height: CGFloat? = 128.0
    
    var slashlink: Slashlink?
    var entry: EntryStub?
    
    override var leadingPadding: CGFloat { return 0 }
    override var trailingPadding: CGFloat { return 0 }
    override var topMargin: CGFloat { return 0 }
    override var bottomMargin: CGFloat { return 0 }
    
    private var img: UIImage?
    
    private func render() {
        guard let textContentStorage = self.textLayoutManager?.textContentManager as? NSTextContentStorage else {
            return
        }
        guard let textElement = textElement else {
            return
        }
        
        let content = textContentStorage.attributedString(for: textElement)
        let rawContent = content?.string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let slashlink = slashlink else {
            TranscludeBlockLayoutFragment.logger.warning("nil slashlink provided to transclude block")
            return
        }
        
        let v = Transclude2View(
            address: MemoAddress.public(slashlink),
            excerpt: entry?.excerpt ?? "MISSING ENTRY",
            action: { }
        )
        
        // Host our SwiftUI view within a UIKit view
        let hosted = UIHostingController(rootView: v)
        guard let view = hosted.view else {
            return
        }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // We have to mount the view before it will actually do layout calculations
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            TranscludeBlockLayoutFragment.logger.warning("Could not find UIWindowScene")
            return
        }
        
        guard let rootView = scene.windows.first?.rootViewController?.view else {
            TranscludeBlockLayoutFragment.logger.warning("Could not find rootViewController")
            return
        }
        
        hosted.view.backgroundColor = .clear
        rootView.addSubview(hosted.view)
        
        // We walk through a bunch of template sizes and check how the view is responding when measured
        // within those bounds. When the view stops growing we know it's at the natural size to
        // fit the text.
        let sizes = [0.0, 16.0, 32.0, 48.0, 64.0, 80.0, 96.0, 100.0, 128.0]
        let width = containerWidth()
        var maxSize = 0.0
        for size in sizes {
            let fit = hosted.sizeThatFits(in: CGSize(width: width, height: size))
            hosted.view.frame = CGRect(origin: CGPoint(x: 0, y: fit.height), size: CGSize(width: 0, height: fit.height))
            hosted.view.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: fit.height))
            let height = hosted.view.intrinsicContentSize.height
            
            TranscludeBlockLayoutFragment.logger.debug("\(size): Height: \(height), Fit: \(fit.height)")
            
            // Skip the first iteration of s == 0 because .sizeThatFits reports the wrong size on the first call
            if fit.height > maxSize && size > 1 {
                maxSize = fit.height
            }
        }
        
        TranscludeBlockLayoutFragment.logger.debug("Max height: \(maxSize)")
        self.height = maxSize
        hosted.view.frame = CGRect(origin: CGPoint(x: 0, y: maxSize), size: CGSize(width: 0, height: maxSize))
        hosted.view.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: maxSize))
        
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
        let r = CGRect(origin: parent.origin, size: CGSize(width: parent.width, height: parent.height + (self.height ?? 0) + 3))
        return r
    }
    
    // Determines the full drawing bounds, should be larger than layoutFragmentFrame
    override var renderingSurfaceBounds: CGRect {
        let w = containerWidth()
        
        let size = super.renderingSurfaceBounds.union(CGRect(x: 0, y: 0, width: w, height: (self.height ?? 128.0)))
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
