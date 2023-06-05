//
//  OmniboxView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct OmniboxView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var phase = 0.0
    
    var address: Slashlink?
    var defaultAudience: Audience
    var status: LoadingState = .loaded

    private func icon() -> Image {
        guard let address = address else {
            return Image(audience: defaultAudience)
        }
        if address.isOurProfile {
            return Image.from(appIcon: .you(colorScheme))
        }
        if address.isProfile {
            return Image.from(appIcon: .user)
        }
        if address.isLocal {
            return Image(audience: .local)
        }
        return Image(audience: .public)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            icon()
                .resizable()
                .frame(width: 17, height: 17)
            
            Spacer(minLength: AppTheme.unit)
            if let slashlink = address {
                OmniboxSlashlinkView(slashlink: slashlink)
            } else {
                Text("Untitled")
                    .foregroundColor(Color.secondary)
            }
            Spacer(minLength: AppTheme.unit)
        }
        .transition(.opacity.combined(with: .scale))
        .foregroundColor(.accentColor)
        .font(.callout)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(height: 34)
        .overlay(
            VStack {
                switch (status) {
                case .loading:
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 1.5,
                                lineCap: .round,
                                dash: [8, 4],
                                dashPhase: phase
                            )
                        )
                        .onAppear {
                            withAnimation(
                                .linear.repeatForever(autoreverses: false)
                            ) {
                                phase -= 20
                            }
                        }
                        .foregroundColor(.accentColor)
                        .opacity(0.5)
                case _:
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(Color.separator, lineWidth: 0.5)
                }
            }
        )
        .frame(minWidth: 100, idealWidth: 240, maxWidth: 240)
    }
}

/// Helper view that knows how to format slashlinks with or without petname.
struct OmniboxSlashlinkView: View {
    var slashlink: Slashlink
    
    var body: some View {
        HStack(spacing: 0) {
            switch slashlink.peer {
            case let .petname(petname) where slashlink.isProfile:
                Text(petname.markup)
                    .fontWeight(.medium)
            case let .petname(petname):
                HStack(spacing: 0) {
                    Text(petname.markup)
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
            case .none where slashlink.isProfile:
                Text("Your profile").foregroundColor(.secondary)
            case .none:
                Text(verbatim: slashlink.slug.description)
            }
        }
        .lineLimit(1)
    }
}

struct OmniboxView_Previews: PreviewProvider {
    struct TappableOmniboxTestView: View {
        var addresses: [Slashlink] = [
            Slashlink("@ksr/red-mars")!,
            Slashlink("@ksr/green-mars")!,
            Slashlink("@ksr/blue-mars")!,
            Slashlink(petname: Petname("ksr")!),
            Slashlink.local(Slug("mars")!),
            Slashlink.local(Slug("a-very-long-note-title-that-goes-on-and-on")!),
            Slashlink("@ksr/a-very-long-note-title-that-goes-on-and-on")!
        ]
        
        @State private var address: Slashlink? = nil
        var defaultAudience = Audience.local
        let status = [LoadingState.loaded, LoadingState.loading].randomElement()!

        var body: some View {
            OmniboxView(
                address: address,
                defaultAudience: defaultAudience,
                status: status
            )
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
                    address: Slashlink("@here/red-mars")!,
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink("@here.now/red-mars-very-long-slug")!,
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink(petname: Petname("ksr")!),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink(petname: Petname("ksr.biz.gov")!),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink("/red-mars")!,
                    defaultAudience: .local
                )
            }
            Group {
                OmniboxView(
                    address: Slashlink(slug: Slug("_profile_")!),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink.local(Slug("red-mars")!),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink.local(Slug("BLUE-mars")!),
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink("@KSR.scifi/GREEN-mars")!,
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink("did:key:abc123/GREEN-mars")!,
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink("did:key:abc123")!,
                    defaultAudience: .local
                )
                OmniboxView(
                    address: Slashlink("/_profile_")!,
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
}
