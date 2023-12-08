//
//  OmniboxView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct OmniboxView: View {
    private static let initialAngle = Double.pi / 8
    private static let fullRotation = Double.pi * 2
    
    @Environment(\.colorScheme) var colorScheme
    // Used to animate the border during loading
    // Value is updated in .onAppear {}
    @State private var phase = Self.initialAngle
    
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
    
    var gradient = Gradient(stops: [
        Gradient.Stop(color: .accentColor.opacity(0), location: 0),
        Gradient.Stop(color: .accentColor.opacity(0), location: 0.75),
        Gradient.Stop(color: .accentColor.opacity(1), location: 1),
    ])
    
    var body: some View {
        HStack(spacing: 8) {
            if status != .loading {
                icon()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 17, height: 17)
            }
            
            Spacer(minLength: AppTheme.unit)
            if let slashlink = address {
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
        .overlay(
            VStack {
                if status == .loading {
                // Loading pulse
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        .conicGradient(
                            gradient,
                            center: .center,
                            angle: Angle.radians(phase)),
                        lineWidth: 2
                    )
                    .animation(
                        .linear(duration: Duration.loading * 2)
                            .repeatForever(autoreverses: false),
                        value: phase
                    )
                    // Keep the view mounted but invisible
                    .opacity(status == .loading ? 0.5 : 0)
                    .task {
                        if status == .loading {
                            phase = Self.initialAngle + Self.fullRotation
                        } 
                    }
                    .onDisappear() {
                        phase = Self.initialAngle
                    }
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
        @State private var status: LoadingState = [LoadingState.loaded, LoadingState.loading].randomElement()!
        var defaultAudience = Audience.local

        var body: some View {
            OmniboxView(
                address: address,
                defaultAudience: defaultAudience,
                status: status
            )
            .onTapGesture {
                withAnimation {
                    self.address = addresses.randomElement()
                    self.status = [LoadingState.loaded, LoadingState.loading].randomElement()!
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
                    address: Slashlink(slug: Slug.profile),
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
