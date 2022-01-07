//
//  PseudoKeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/28/21.
//

import SwiftUI

/// A view with a toolbar at the bottom, and a corresponding
/// area up top that is the height of the area minus the toolbar.
struct PseudoKeyboardToolbarView<Content, Toolbar>: View
where Content: View, Toolbar: View
{
    var isKeyboardUp: Bool
    var toolbarHeight: CGFloat
    var toolbar: Toolbar
    var content: (Bool, CGSize) -> Content

    /// Set fixed toolbar height for view.
    /// Defaults to 48pt.
    func toolbarHeight(_ height: CGFloat) -> Self {
        var view = self
        view.toolbarHeight = height
        return view
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                content(
                    isKeyboardUp,
                    (
                        isKeyboardUp ?
                        CGSize(
                            width: geometry.size.width,
                            height: geometry.size.height - toolbarHeight
                        ) :
                        geometry.size
                     )
                )
                if isKeyboardUp {
                    toolbar
                        .frame(height: toolbarHeight)
                        .transition(.opacity)
                }
            }
        }
    }
}
