//
//  BylineSmView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

/// Compact byline combines a small profile pic, username, and path
struct BylineSmView: View {
    var pfp: Image
    var petname: String
    var slug: String

    var body: some View {
        HStack {
            ProfilePicSm(image: pfp)
            HStack(spacing: 0) {
                Text(verbatim: petname)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                Text(verbatim: slug)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BylineSmView_Previews: PreviewProvider {
    static var previews: some View {
        BylineSmView(
            pfp: Image("pfp-dog"),
            petname: "@name",
            slug: "/path"
        )
    }
}
