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
    private var petnameColor = Color.accentColor
    private var slugColor = Color.secondary
    
    var body: some View {
        HStack(spacing: 0) {
            if let petname = petname {
                Text(verbatim: "@\(petname)")
                    .fontWeight(.medium)
                    .foregroundColor(petnameColor)
            }
            Text(verbatim: "/\(slug)")
                .foregroundColor(slugColor)
        }
        .lineLimit(1)
    }
    
    func theme(
        petname petnameColor: Color = Color.accentColor,
        slug slugColor: Color = Color.secondary
    ) -> Self {
        var this = self
        this.petnameColor = petnameColor
        this.slugColor = slugColor
        return this
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
