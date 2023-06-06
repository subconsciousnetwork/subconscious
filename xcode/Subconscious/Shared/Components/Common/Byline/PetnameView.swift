//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

public enum Name {
    case known(Petname)
    case named(Slashlink, Petname.Name)
    case unknown(Slashlink)
}

/// Byline style for displaying a petname
struct PetnameView: View {
    var name: Name
    
    var body: some View {
        switch name {
        case .known(let name):
            Text(name.markup)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
        case .named(let address, let name):
                VStack(alignment: .leading, spacing: AppTheme.unit) {
                    Text(name.description)
                        .italic()
                        .fontWeight(.medium)
                    if let peer = address.peer?.markup {
                        HStack(spacing: AppTheme.unit) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius/2)
                                    .foregroundColor(.secondaryBackground)
                                Text("AKA")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 10))
                            }
                            .frame(width: 28, height: 15)
                            
                            Text(peer)
                                .foregroundColor(.secondary)
                                .fontWeight(.regular)
                                .font(.caption)
                        }
                    }
                }
        case .unknown(let address):
                Text(address.peer?.markup ?? address.markup)
                    .lineLimit(1)
                    .fontWeight(.medium)
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
                    Petname("robert")!
                )
            )
        }
    }
}
