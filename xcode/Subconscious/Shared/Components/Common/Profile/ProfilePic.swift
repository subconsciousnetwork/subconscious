//
//  ProfilePic.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

enum ProfilePicVariant: Equatable, Codable, Hashable {
    case none(Did)
    case url(URL)
    case image(String)
}

struct ProfilePicImage: View {
    var image: Image
    
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.separator, lineWidth: 0.5))
    }
}

struct ProfilePic: View {
    var pfp: ProfilePicVariant
    var body: some View {
        switch pfp {
        case .none(let did):
            GenerativeProfilePic(did: did)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.separator, lineWidth: 0.5))
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
                pfp: .none(Did.dummyData())
            )
            ProfilePic(
                pfp: .url(URL(string: "https://images.unsplash.com/photo-1577766729821-6003ae138e18")!)
            )
            ProfilePic(
                pfp: .image("pfp-dog")
            )
        }
    }
}
