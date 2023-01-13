//
//  BylineView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

/// Byline combines a small profile pic, username, and path
struct BylineView: View {
    var pfp: Image
    var petname: String
    var slug: String

    var body: some View {
        HStack {
            ProfilePicSm(image: pfp)
            HStack(spacing: 0) {
                Text(verbatim: petname)
                    .bold()
                    .foregroundColor(.accentColor)
                Text(verbatim: slug)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BylineView_Previews: PreviewProvider {
    static var previews: some View {
        BylineView(
            pfp: Image("pfp-dog"),
            petname: "@name",
            slug: "/path"
        )
    }
}
