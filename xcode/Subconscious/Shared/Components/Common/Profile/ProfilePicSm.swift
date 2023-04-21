//
//  ProfilePicSm.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct ProfilePicSm: View {
    var url: URL
    var border = Color.background

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(border, lineWidth: 1)
                )
                .clipShape(Circle())
        } placeholder: {
            ProgressView()
        }
    }
}

struct ProfilePicSm_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePicSm(
            url: URL(string: "pfp-dog")!
        )
    }
}
