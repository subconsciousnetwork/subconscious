//
//  ProfilePicSm.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct ProfilePicSmImage: View {
    var image: Image
    var border: Color
    
    var body: some View {
        image
            .resizable()
            .frame(width: 24, height: 24)
            .overlay(
                Circle()
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(Circle())
    }
}

struct ProfilePicSm: View {
    var pfp: ProfilePicVariant
    var border = Color.background

    var body: some View {
        switch pfp {
        case .none:
            ProfilePicSmImage(image: Image("sub_logo"), border: border)
        case .url(let url):
            AsyncImage(url: url) { image in
                ProfilePicSmImage(image: image, border: border)
            } placeholder: {
                ProgressView()
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(border, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
        case .image(let img):
            ProfilePicSmImage(image: Image(img), border: border)
        }
    }
}

struct ProfilePicSm_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ProfilePicSm(
                pfp: .none
            )
            ProfilePicSm(
                pfp: .url(URL(string: "https://d2w9rnfcy7mm78.cloudfront.net/14547710/original_69c752e0010ef82be2792c16b1339663.gif?1641203279?bc=0")!)
            )
            ProfilePicSm(
                pfp: .image("pfp-dog")
            )
        }
    }
}
