//
//  SlashlinkBylineView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI

/// Compact byline combines a small profile pic, username, and path
struct SlashlinkBylineView: View {
    var petname: String?
    var slug: String

    var body: some View {
        HStack(spacing: 0) {
            if let petname = petname {
                Text(verbatim: "@\(petname)")
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
            }
            Text(verbatim: "/\(slug)")
                .foregroundColor(.secondary)
        }
        .lineLimit(1)
    }
}

extension SlashlinkBylineView {
    init(
        slashlink: Slashlink
    ) {
        self.init(
            petname: slashlink.petnamePart,
            slug: slashlink.slugPart
        )
    }
}

struct SlashlinkBylineView_Previews: PreviewProvider {
    static var previews: some View {
        SlashlinkBylineView(
            slashlink: Slashlink("@melville/the-whale-the-whale")!
        )
    }
}
