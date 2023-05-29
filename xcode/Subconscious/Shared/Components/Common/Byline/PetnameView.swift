//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

/// Byline style for displaying a petname
struct PetnameView: View {
    var address: Slashlink
    var name: Petname?
    
    var body: some View {
        if let name = name {
            VStack(alignment: .leading) {
                Text(name.description)
                if let peer = address.peer?.markup {
                    Text(peer)
                        .foregroundColor(.secondary)
                        .fontWeight(.regular)
                        .font(.caption)
                }
            }
        } else {
            Text(address.peer?.markup ?? address.markup)
                .lineLimit(1)
        }
    }
}

extension PetnameView {
    init(address: Slashlink, name: Petname.Name?) {
        self.address = address
        self.name = name?.toPetname()
    }
}

struct PetnameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameView(
                address: Slashlink(petname: Petname("melville.bobby.tables")!),
                name: Petname.Name("melville")!
            )
            PetnameView(
                address: Slashlink(petname: Petname("bobby.tables")!)
            )
            PetnameView(
                address: Slashlink(petname: Petname("tables.bobby")!),
                name: Petname("tables")!
            )
            PetnameView(
                address: Slashlink(petname: Petname("tables")!)
            )
            .frame(maxWidth: 128)
        }
    }
}
