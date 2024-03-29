//
//  BylineSmView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

/// Compact byline combines a small profile pic, username, and path
struct BylineSmView: View {
    var pfp: ProfilePicVariant
    var slashlink: Slashlink
    var highlight: Color = .accentColor
    
    var body: some View {
        HStack {
            ProfilePic(pfp: pfp, size: .small)
            SlashlinkDisplayView(slashlink: slashlink)
                .theme(base: highlight, slug: .secondary)
        }
    }
}

struct BylineSmView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BylineSmView(
                pfp: .image("pfp-dog"),
                slashlink: Slashlink("@name/path")!
            )
            
            BylineSmView(
                pfp: .generated(Did.dummyData()),
                slashlink: Slashlink("@name/path")!
            )

            BylineSmView(
                pfp: .generated(Did.local),
                slashlink: Slashlink("@name/path")!
            )
        }
    }
}
