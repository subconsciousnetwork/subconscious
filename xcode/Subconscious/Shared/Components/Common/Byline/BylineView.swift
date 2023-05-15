//
//  BylineView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/16/23.
//

import SwiftUI

/// Full-sized byline, suitable for using as header of story
struct BylineView: View {
    var pfp: ProfilePicVariant
    var name: String
    var petname: String
    var slug: String
    
    var body: some View {
        HStack(spacing: AppTheme.unit3) {
            ProfilePic(pfp: pfp, size: .large)
            VStack(alignment: .leading) {
                Text(verbatim: name)
                    .foregroundColor(.buttonText)
                    .fontWeight(.semibold)
                HStack(spacing: 0) {
                    Text(verbatim: petname)
                        .fontWeight(.semibold)
                    Text(verbatim: slug)
                }
                .foregroundColor(.secondary)
            }
        }
    }
}

struct BylineView_Previews: PreviewProvider {
    static var previews: some View {
        BylineView(
            pfp: .image("pfp-dog"),
            name: "Dog",
            petname: "@name",
            slug: "/path"
        )
    }
}
