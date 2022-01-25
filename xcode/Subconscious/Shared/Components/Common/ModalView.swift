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
        if isPresented {
            ZStack(alignment: .top) {
                ScrimView()
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1)
                    .onTapGesture {
                        isPresented = false
                    }
                VStack {
                    DialogView(content: content)
                    Spacer()
                }
                .zIndex(2)
                .padding()
            }
            .transition(.opacity)
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
