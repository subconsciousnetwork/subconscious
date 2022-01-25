//
//  ModalView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/25/22.
//

import SwiftUI

/// Modal window
struct ModalView<Content>: View
where Content: View {
    var content: Content

    var body: some View {
        VStack {
            content
        }
        .frame(maxWidth: .infinity)
        .background(Color.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppTheme.cornerRadius
            )
        )
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Rectangle().background(.black)
            ModalView(
                content: Text("Floop")
            )
        }
    }
}
