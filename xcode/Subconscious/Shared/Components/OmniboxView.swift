//
//  OmniboxView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct OmniboxView: View {
    var address: MemoAddress?
    var defaultAudience: Audience

    var body: some View {
        HStack(spacing: 8) {
            Image(audience: address?.toAudience() ?? defaultAudience)
                .resizable()
                .frame(width: 17, height: 17)
            Spacer(minLength: AppTheme.unit)
            if let slashlink = address?.toSlashlink() {
                OmniboxSlashlinkView(
                    petname: slashlink.petnamePart,
                    slug: slashlink.slugPart
                )
            }
            Spacer(minLength: AppTheme.unit)
        }
        .foregroundColor(.accentColor)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(height: 34)
        .clipShape(Capsule())
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(Color.separator, lineWidth: 0.5)
        )
        .frame(minWidth: 100, idealWidth: 240, maxWidth: 240)
    }
}

/// Helper view that knows how to format slashlinks with or without petname.
struct OmniboxSlashlinkView: View {
    var petname: String?
    var slug: String
    var empty = ""
    
    var body: some View {
        HStack(spacing: 0) {
            if let petname = petname {
                Text(verbatim: "@\(petname)").fontWeight(.medium)
                Text(verbatim: "/\(slug)")
            } else {
                Text(verbatim: slug)
            }
        }
        .lineLimit(1)
    }
}

struct OmniboxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OmniboxView(
                address: .public(Slashlink("@here/red-mars")!),
                defaultAudience: .local
            )
            OmniboxView(
                address: .public(Slashlink("@here/red-mars-very-long-slug")!),
                defaultAudience: .local
            )
            OmniboxView(
                address: .public(Slashlink("/red-mars")!),
                defaultAudience: .local
            )
            OmniboxView(
                address: .local(Slug("red-mars")!),
                defaultAudience: .local
            )
            OmniboxView(
                address: .local(Slug("red-mars")!),
                defaultAudience: .local
            )
            OmniboxView(
                defaultAudience: .local
            )
            OmniboxView(
                defaultAudience: .public
            )
            OmniboxView(
                address: .local(Slug("red-mars")!),
                defaultAudience: .local
            )
        }
    }
}
