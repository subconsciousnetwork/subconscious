//
//  ProfilePic.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct ProfilePic: View {
    var url: URL
    var body: some View {
        AsyncImage(url: url) { image in
        image
            .resizable()
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.separator, lineWidth: 0.5))
        } placeholder: {
            ProgressView()
        }
        
    }
}

struct ProfilePic_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePic(
            url: URL(string: "pfp-dog")!
        )
    }
}
