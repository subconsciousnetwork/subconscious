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
            .aspectRatio(contentMode: .fill)
            .frame(width: 32, height: 32)
            .overlay(
                Circle()
                    .stroke(Color.separator, lineWidth: 1)
            )
            .clipShape(Circle())
    }
}

struct ProfilePicSm: View {
    var pfp: ProfilePicVariant
    var border = Color.background

    var body: some View {
        switch pfp {
        case .none(let did):
            GenerativeProfilePic(did: did, size: 32)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.separator, lineWidth: 1))
        case .url(let url):
            AsyncImage(url: url) { image in
                ProfilePicSmImage(image: image, border: border)
            } placeholder: {
                ProgressView()
                    .frame(width: 32, height: 32)
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
                pfp: .none(Did.dummyData())
            )
            ProfilePicSm(
                pfp: .url(URL(string: "https://images.unsplash.com/photo-1577766729821-6003ae138e18")!)
            )
            ProfilePicSm(
                pfp: .image("pfp-dog")
            )
        }
    }
}
