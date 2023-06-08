//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

public enum NameVariant {
    case known(Slashlink, Petname.Name)
    case named(Slashlink, Petname.Name)
    case unknown(Slashlink)
}

struct PeerView: View {
    var peer: Peer

    var body: some View {
        HStack(spacing: AppTheme.unit) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius/2)
                    .foregroundColor(.secondaryBackground)
                Text("AKA")
                    .foregroundColor(.secondary)
                    .font(.system(size: 10))
            }
            .frame(width: 28, height: 15)

            Text(peer.markup)
                .foregroundColor(.secondary)
                .fontWeight(.regular)
                .font(.caption)
        }
    }
}

/// Byline style for displaying a petname
struct PetnameView: View {
    var name: NameVariant
    var annotation: String? = nil
    
    public func annotated(with annotation: String) -> Self {
        var this = self
        this.annotation = annotation
        return this
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            switch name {
            case .known(let address, let name):
                Text(name.toPetname().markup)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                // Ensure we do not show the exact same name twice
                if let peer = address.peer,
                   let petname = address.petname,
                   petname.leaf != name {
                    PeerView(peer: peer)
                }
            case .named(let address, let name):
                Text("\(annotation ?? "")\(name.description)")
                    .italic()
                    .fontWeight(.medium)
                if let peer = address.peer {
                    PeerView(peer: peer)
                }
            case .unknown(let address):
                Text(address.peer?.markup ?? address.markup)
                    .lineLimit(1)
                    .fontWeight(.medium)
            }
        }
    }
}

extension PetnameView {
    init(address: Slashlink, name: Petname.Name?) {
        if let name = name {
            self.name = NameVariant.named(address, name)
        } else {
            self.name = NameVariant.unknown(address)
        }
    }
}

struct PetnameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameView(
                name: .named(
                    Slashlink(profile: Petname("melville.bobby.tables")!),
                    Petname.Name("melville")!
                )
            )
            PetnameView(
                name: .unknown(
                    Slashlink(profile: Petname("melville.bobby.tables")!)
                )
            )
            PetnameView(
                name: .known(
                    Slashlink(profile: Petname("robert")!),
                    Petname.Name("robert")!
                )
            )
        }
    }
}
