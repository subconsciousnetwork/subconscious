//
//  PseudoKeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/28/21.
//

import SwiftUI

struct PseudoKeyboardToolbarView<Content, Toolbar>: View
where Content: View, Toolbar: View
{
    var isKeyboardUp: Bool
    var content: Content
    var toolbar: Toolbar
    var toolbarHeight: CGFloat = 48

    init(
        isKeyboardUp: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder toolbar: () -> Toolbar
    ) {
        self.isKeyboardUp = isKeyboardUp
        self.content = content()
        self.toolbar = toolbar()
    }

    /// Set fixed toolbar height for view.
    /// Defaults to 48pt.
    func toolbarHeight(_ height: CGFloat) -> Self {
        var view = self
        view.toolbarHeight = height
        return view
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                content
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
