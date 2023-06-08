//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

public enum Name {
    case known(Petname.Name, Slashlink?)
    case named(Slashlink, Petname.Name)
    case unknown(Slashlink)
}

struct AddressView: View {
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
    var name: Name
    var annotation: String? = nil
    
    public func prefix(msg: String) -> Self {
        var this = self
        this.annotation = msg
        return this
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            switch name {
            case .known(let name, let address):
                Text(name.toPetname().markup)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                // Ensure we do not show the exact same name twice
                if let peer = address?.peer,
                   let petname = address?.petname,
                   petname.leaf != name {
                    AddressView(peer: peer)
                }
            case .named(let address, let name):
                Text("\(annotation ?? "")\(name.description)")
                    .italic()
                    .fontWeight(.medium)
                if let peer = address.peer {
                    AddressView(peer: peer)
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
            self.name = Name.named(address, name)
        } else {
            self.name = Name.unknown(address)
        }
    }
}

struct PetnameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameView(
                name: .named(
                    Slashlink(petname: Petname("melville.bobby.tables")!),
                    Petname.Name("melville")!
                )
            )
            PetnameView(
                name: .unknown(
                    Slashlink(petname: Petname("melville.bobby.tables")!)
                )
            )
            PetnameView(
                name: .known(
                    Petname.Name("robert")!,
                    nil
                )
            )
        }
    }
}
