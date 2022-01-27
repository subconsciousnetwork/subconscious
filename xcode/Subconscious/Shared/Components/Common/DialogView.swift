//
//  ModalView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/25/22.
//

import SwiftUI

/// Modal window
struct DialogView<Content>: View
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
                cornerRadius: AppTheme.cornerRadiusLg
            )
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}

struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        DialogView(
            content: Text("Floop")
        )
    }
}
