//
//  SlashlinkBylineView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI

/// Compact byline combines a small profile pic, username, and path
struct SlashlinkBylineView: View {
    var slashlink: Slashlink
    var petnameColor = Color.accentColor
    var slugColor = Color.secondary
    
    var body: some View {
        HStack(spacing: 0) {
            if let petname = slashlink.toPetname() {
                PetnameBylineView(petname: petname)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
            }
            Text(verbatim: slashlink.slug.verbatimMarkup)
                .foregroundColor(slugColor)
            Spacer()
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

struct SlashlinkBylineView_Previews: PreviewProvider {
    static var previews: some View {
        SlashlinkBylineView(
            slashlink: Slashlink("@melville/the-whale-the-whale")!
        )
    }
}
