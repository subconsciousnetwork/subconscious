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
    var slashlink: Slashlink
    
    var body: some View {
        HStack {
            ProfilePicSm(image: pfp)
            SlashlinkBylineView(slashlink: slashlink)
        }
    }
}

struct BylineSmView_Previews: PreviewProvider {
    static var previews: some View {
        BylineSmView(
            pfp: Image("pfp-dog"),
            slashlink: Slashlink("@name/path")!
        )
    }
}
