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
    var petname: Petname
    
    var body: some View {
        if let address = address {
            VStack(alignment: .leading) {
                Text(petname.description)
                Text(address.petname?.markup ?? address.markup)
                    .foregroundColor(.secondary)
                    .fontWeight(.regular)
                    .font(.caption)
            }
        } else {
            Text(petname.markup)
                .lineLimit(1)
        }
    }
}

extension PetnameView {
    init(identifier: Petname.Part) {
        self.petname = identifier.toPetname()
    }
    
    init(address: Slashlink, identifier: Petname.Part) {
        self.address = address
        self.petname = identifier.toPetname()
    }
}

struct PetnameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameView(
                address: Slashlink(petname: Petname("melville.bobby.tables")!),
                identifier: Petname.Part("melville")!
            )
            PetnameView(
                identifier: Petname.Part("bobby.tables")!
            )
            PetnameView(
                address: Slashlink(petname: Petname("tables.bobby")!),
                petname: Petname("tables")!
            )
            PetnameView(
                petname: Petname("tables")!
            )
            .frame(maxWidth: 128)
        }
    }
}
