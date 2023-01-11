//
//  BylineView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

/// Byline combines a small profile pic, username, and path
struct BylineView: View {
    var image: Image
    var petname: String
    var slug: Slug

    var body: some View {
        HStack {
            ProfilePicSm(image: image)
            HStack(spacing: 0) {
                Text(verbatim: petname)
                    .bold()
                    .foregroundColor(.accentColor)
                Text(verbatim: slug.toSlashlink())
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BylineView_Previews: PreviewProvider {
    static var previews: some View {
        BylineView(
            image: Image("pfp-dog"),
            petname: "name",
            slug: Slug("path")!
        )
    }
}
