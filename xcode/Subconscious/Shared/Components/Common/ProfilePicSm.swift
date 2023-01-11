//
//  ProfilePicSm.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct ProfilePicSm: View {
    var image: Image
    var body: some View {
        image
            .resizable()
            .frame(width: 24, height: 24)
            .clipShape(Circle())
    }
}

struct ProfilePicSm_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePicSm(
            image: Image("pfp-dog")
        )
    }
}
