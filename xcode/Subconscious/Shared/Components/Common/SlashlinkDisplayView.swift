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
    var baseColor = Color.accentColor
    var slugColor = Color.accentColor
    var labelColor = Color.secondary
    
    var body: some View {
        HStack(spacing: 0) {
            switch slashlink.peer {
            case let .petname(petname) where slashlink.isProfile:
                PetnameView(petname: petname)
                    .foregroundColor(baseColor)
                    .fontWeight(.medium)
            case let .petname(petname):
                HStack(spacing: 0) {
                    PetnameView(petname: petname)
                        .foregroundColor(baseColor)
                        .fontWeight(.medium)
                    Text(verbatim: slashlink.slug.markup)
                        .foregroundColor(slugColor)
                }
            case let .did(did) where slashlink.isProfile:
                Text(verbatim: did.description)
                    .foregroundColor(baseColor)
                    .fontWeight(.medium)
            case let .did(did) where did.isLocal:
                Text(verbatim: slashlink.slug.description)
                    .foregroundColor(slugColor)
            case let .did(did):
                HStack(spacing: 0) {
                    Text(verbatim: did.description)
                        .foregroundColor(baseColor)
                        .fontWeight(.medium)
                    Text(verbatim: slashlink.slug.markup)
                        .foregroundColor(slugColor)
                }
            case .none where slashlink.isProfile:
                Text("Your profile")
                    .foregroundColor(labelColor)
            case .none:
                Text(verbatim: slashlink.slug.description)
                    .foregroundColor(slugColor)
            }
        }
        .lineLimit(1)
    }
    
    func theme(
        base baseColor: Color = Color.accentColor,
        slug slugColor: Color = Color.accentColor,
        label labelColor: Color = Color.secondary
    ) -> Self {
        var this = self
        this.baseColor = baseColor
        this.slugColor = slugColor
        this.labelColor = labelColor
        return this
    }
}

struct SlashlinkDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                SlashlinkDisplayView(
                    slashlink: Slashlink("/foo")!
                )
                SlashlinkDisplayView(
                    slashlink: Slashlink("/foo")!
                ).foregroundColor(.accentColor)
                SlashlinkDisplayView(
                    slashlink: Slashlink("/foo/bar")!
                )
                SlashlinkDisplayView(
                    slashlink: Slashlink("/_profile_")!
                )
            }
            Group {
                SlashlinkDisplayView(
                    slashlink: Slashlink("@alice/foo/bar")!
                )
                SlashlinkDisplayView(
                    slashlink: Slashlink("@bob.alice/foo/bar")!
                )
                SlashlinkDisplayView(
                    slashlink: Slashlink("@bob.alice/_profile_")!
                )
            }
            Group {
                SlashlinkDisplayView(
                    slashlink: Slashlink("did:key:abc123/foo/bar")!
                )
                SlashlinkDisplayView(
                    slashlink: Slashlink("did:key:abc123")!
                )
                SlashlinkDisplayView(
                    slashlink: Slashlink("did:key:abc123/_profile_")!
                )
            }
            Group {
                SlashlinkDisplayView(
                    slashlink: Slashlink("did:subconscious:local/foo")!
                )
                SlashlinkDisplayView(
                    slashlink: Slashlink("did:subconscious:local")!
                )
            }
        }
    }
}
