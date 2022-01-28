//
//  ModalView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/25/22.
//

import SwiftUI

struct ModalView<Content>: View
where Content: View {
    @Binding var isPresented: Bool
    var content: Content
    var keyboardHeight: CGFloat
    var body: some View {
        GeometryReader { geometry in
            if isPresented {
                ScrimView()
                    .ignoresSafeArea(.all)
                    .zIndex(1)
                    .transition(.opacity)
                    .onTapGesture {
                        isPresented = false
                    }
            }
            if isPresented {
                DialogView(
                    content: content
                )
                .padding(.horizontal, AppTheme.unit2)
                .padding(.bottom, AppTheme.unit * 8)
                .frame(
                    maxHeight: (
                        geometry.size.height -
                        keyboardHeight +
                        geometry.safeAreaInsets.bottom
                    )
                )
                .zIndex(2)
                .transition(
                    .opacity.combined(with: .scale(scale: 0.9))
                )
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalView(
            isPresented: .constant(true),
            content: Text("Floop"),
            keyboardHeight: 350
        )
    }
}
