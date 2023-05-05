//
//  SlashlinkDisplayView.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/5/23.
//

import SwiftUI

/// A view for slashlinks, optimized for compact display
struct SlashlinkDisplayView: View {
    var slashlink: Slashlink
    
    var body: some View {
        switch slashlink.peer {
        case let .petname(petname) where slashlink.isProfile:
            PetnameView(petname: petname)
                .fontWeight(.medium)
        case let .petname(petname):
            HStack(spacing: 0) {
                PetnameView(petname: petname)
                    .fontWeight(.medium)
                Text(verbatim: slashlink.slug.markup)
            }
        case let .did(did) where slashlink.isProfile:
            Text(verbatim: did.description)
                .fontWeight(.medium)
        case let .did(did) where did.isLocal:
            Text(verbatim: slashlink.slug.description)
        case let .did(did):
            HStack(spacing: 0) {
                Text(verbatim: did.description)
                    .fontWeight(.medium)
                Text(verbatim: slashlink.slug.markup)
            }
        case .none:
            Text(verbatim: slashlink.slug.description)
        }
    }
}

struct SlashlinkDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SlashlinkDisplayView(
                slashlink: Slashlink("/foo")!
            )
            SlashlinkDisplayView(
                slashlink: Slashlink("/foo/bar")!
            )
            SlashlinkDisplayView(
                slashlink: Slashlink("@alice/foo/bar")!
            )
            SlashlinkDisplayView(
                slashlink: Slashlink("@bob.alice/foo/bar")!
            )
            SlashlinkDisplayView(
                slashlink: Slashlink("did:key:abc123/foo/bar")!
            )
            SlashlinkDisplayView(
                slashlink: Slashlink("did:key:abc123")!
            )
        }
    }
}
