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
    var content: (CGSize) -> Content

    /// Set fixed toolbar height for view.
    /// Defaults to 48pt.
    func toolbarHeight(_ height: CGFloat) -> Self {
        var view = self
        view.toolbarHeight = height
        return view
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    content(
                        (
                            isKeyboardUp ?
                            CGSize(
                                width: geometry.size.width,
                                height: geometry.size.height - toolbarHeight
                            ) :
                            geometry.size
                         )
                    )
                }
                .padding(.bottom, isKeyboardUp ? toolbarHeight : 0)
                VStack(spacing: 0) {
                    Spacer()
                    toolbar
                        .frame(height: toolbarHeight)
                        .opacity(isKeyboardUp ? 1 : 0)
                        .offset(
                            x: 0,
                            y: isKeyboardUp ? 0 : toolbarHeight
                        )
                        .animation(.default, value: isKeyboardUp)
                }
            }
        }
    }
}
