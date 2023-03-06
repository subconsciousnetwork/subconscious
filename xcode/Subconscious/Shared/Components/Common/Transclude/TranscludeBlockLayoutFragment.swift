//
//  TranscludeBlockLayoutFragment.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/2/2023.
//

import os
import SwiftUI

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoreGraphics

class TranscludeBlockLayoutFragment: NSTextLayoutFragment {
    static var logger = Logger(
        subsystem: Config.default.rdns,
        category: "editor"
    )

    override var leadingPadding: CGFloat { return 0 }
    override var trailingPadding: CGFloat { return 0 }
    override var topMargin: CGFloat { return 0 }
    override var bottomMargin: CGFloat { return 0 }
    
    private func withTranslation(x: CGFloat, y: CGFloat, ctx: CGContext, perform: (CGContext) -> Void) {
        ctx.translateBy(x: x, y: y)
        perform(ctx)
        ctx.translateBy(x: -x, y: -y)
    }
    
    override func draw(at renderingOrigin: CGPoint, in ctx: CGContext) {
        ctx.saveGState()
        
        // DEBUG: render border around entire draw surface
        withTranslation(x: leadingPadding, y: 0, ctx: ctx) { ctx in
            ctx.stroke(CGRect(origin: renderingSurfaceBounds.origin, size: renderingSurfaceBounds.size))
        }
        
        ctx.restoreGState()
        
        // Draw the text on top.
        super.draw(at: renderingOrigin, in: ctx)
    }
}
