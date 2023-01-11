//
//  ProfilePicMd.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct ProfilePicMd: View {
    var image: Image
    var body: some View {
        image
            .resizable()
            .frame(width: 32, height: 32)
            .clipShape(Circle())
    }
}

struct ProfilePicMd_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePicMd(
            image: Image("pfp-dog")
        )
    }
}
