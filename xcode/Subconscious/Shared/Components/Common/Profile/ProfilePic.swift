//
//  ProfilePic.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

enum ProfilePicVariant: Equatable, Codable, Hashable {
    case none
    case url(URL)
    case image(String)
}

struct ProfilePicImage: View {
    var image: Image
    
    var body: some View {
        image
            .resizable()
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.separator, lineWidth: 0.5))
    }
}

struct ProfilePic: View {
    var pfp: ProfilePicVariant
    var body: some View {
        switch pfp {
        case .none:
            ProfilePicImage(image: Image("sub_logo"))
        case .url(let url):
            AsyncImage(url: url) { image in
                ProfilePicImage(image: image)
            } placeholder: {
                ProgressView()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.separator, lineWidth: 0.5))
            }
        case .image(let img):
            ProfilePicImage(image: Image(img))
        }
    }
}

struct ProfilePic_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProfilePic(
                pfp: .none
            )
            ProfilePic(
                pfp: .url(URL(string: "https://d2w9rnfcy7mm78.cloudfront.net/14547710/original_69c752e0010ef82be2792c16b1339663.gif?1641203279?bc=0")!)
            )
            ProfilePic(
                pfp: .image("pfp-dog")
            )
        }
    }
}
