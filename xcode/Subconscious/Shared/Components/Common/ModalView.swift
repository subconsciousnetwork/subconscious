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
    var size: CGSize
    var body: some View {
        ZStack(alignment: .top) {
            if isPresented {
                ScrimView()
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1)
                    .transition(.opacity)
                    .onTapGesture {
                        isPresented = false
                    }
            }
            if isPresented {
                VStack {
                    DialogView(content: content)
                    Spacer()
                }
                .frame(
                    maxWidth: size.width,
                    maxHeight: size.height
                )
                .padding()
                .zIndex(2)
                .transition(
                    .opacity.combined(with: .scale(scale: 0.9))
                )
            }
        }
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalView(
            isPresented: .constant(true),
            content: Text("Floop"),
            size: CGSize(width: 100, height: 100)
        )
    }
}
