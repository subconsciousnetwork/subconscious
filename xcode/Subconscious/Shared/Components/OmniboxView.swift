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

    private func icon() -> Image {
        if let address = address {
            return address.isOurProfile
                ? AppIcon.you
                : AppIcon.user
        }
        
        let audience = address?.toAudience() ?? defaultAudience
        return Image(audience: audience)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            icon()
                .resizable()
                .frame(width: 17, height: 17)
            
            Spacer(minLength: AppTheme.unit)
            if let slashlink = address?.toSlashlink() {
                OmniboxSlashlinkView(slashlink: slashlink)
            } else {
                Text("Untitled")
                    .foregroundColor(Color.secondary)
            }
            Spacer(minLength: AppTheme.unit)
        }
        .transition(.opacity)
        .foregroundColor(.accentColor)
        .font(.callout)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(height: 34)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(Color.separator, lineWidth: 0.5)
        )
        .frame(minWidth: 100, idealWidth: 240, maxWidth: 240)
    }
}

/// Helper view that knows how to format slashlinks with or without petname.
struct OmniboxSlashlinkView: View {
    var slashlink: Slashlink
    
    var body: some View {
        HStack(spacing: 0) {
            switch (slashlink.slug.isProfile(), slashlink.petname) {
            case (true, .some(let petname)):
                PetnameBylineView(petname: petname)
            case (false, .some(let petname)):
                PetnameBylineView(petname: petname)
                Text(verbatim: slashlink.slug.verbatimMarkup)
            case (true, .none):
                Text(verbatim: "Your profile").foregroundColor(.secondary)
            case (false, .none):
                Text(verbatim: slashlink.slug.verbatim)
            }
        }
        .lineLimit(1)
    }
}

struct OmniboxView_Previews: PreviewProvider {
    struct TappableOmniboxTestView: View {
        var addresses: [MemoAddress] = [
            MemoAddress.public(Slashlink("@ksr/red-mars")!),
            MemoAddress.public(Slashlink("@ksr/green-mars")!),
            MemoAddress.public(Slashlink("@ksr/blue-mars")!),
            MemoAddress.public(Slashlink(petname: Petname("ksr")!)),
            MemoAddress.local(Slug("mars")!),
            MemoAddress.local(Slug("a-very-long-note-title-that-goes-on-and-on")!),
            MemoAddress.public(Slashlink("@ksr/a-very-long-note-title-that-goes-on-and-on")!)
        ]
        
        @State private var address: MemoAddress? = nil
        var defaultAudience = Audience.local

        var body: some View {
            OmniboxView(address: address, defaultAudience: defaultAudience)
                .onTapGesture {
                    withAnimation {
                        self.address = addresses.randomElement()
                    }
                }
        }
    }

    static var previews: some View {
        VStack {
            VStack {
                Text("Tap me")
                TappableOmniboxTestView()
            }
            Divider()
            Group {
                OmniboxView(
                    address: .public(Slashlink("@here/red-mars")!),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: .public(Slashlink("@here.now/red-mars-very-long-slug")!),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: .public(Slashlink(petname: Petname("ksr")!)),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: .public(Slashlink(petname: Petname("ksr.biz.gov")!)),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: .public(Slashlink("/red-mars")!),
                    defaultAudience: .local
                )
            }
            OmniboxView(
                address: .local(Slug("_profile_")!),
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
        }
    }
}
