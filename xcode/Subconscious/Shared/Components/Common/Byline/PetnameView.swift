//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

/// Byline style for displaying a petname
struct PetnameView: View {
    var address: Slashlink?
    var name: Petname
    
    var body: some View {
        if let address = address {
            VStack(alignment: .leading) {
                Text(name.description)
                Text(address.petname?.markup ?? address.markup)
                    .foregroundColor(.secondary)
                    .fontWeight(.regular)
                    .font(.caption)
            }
        } else {
            Text(name.markup)
                .lineLimit(1)
        }
    }
}

extension PetnameView {
    init(name: Petname.Part) {
        self.name = name.toPetname()
    }
    
    init(address: Slashlink, name: Petname.Part) {
        self.address = address
        self.name = name.toPetname()
    }
}

struct PetnameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameView(
                address: Slashlink(petname: Petname("melville.bobby.tables")!),
                name: Petname.Part("melville")!
            )
            PetnameView(
                name: Petname.Part("bobby.tables")!
            )
            PetnameView(
                address: Slashlink(petname: Petname("tables.bobby")!),
                name: Petname("tables")!
            )
            PetnameView(
                name: Petname("tables")!
            )
            .frame(maxWidth: 128)
        }
    }
}
