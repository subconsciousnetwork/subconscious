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
                .zIndex(2)
                .padding()
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
            content: Text("Floop")
        )
    }
}
