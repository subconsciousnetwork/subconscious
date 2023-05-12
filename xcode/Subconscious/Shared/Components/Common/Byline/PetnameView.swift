//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

/// Byline style for displaying a petname
struct PetnameView: View {
    var petname: Petname
    var address: Slashlink?
    
    var body: some View {
        if let address = address?.petname {
            VStack(alignment: .leading) {
                Text(petname.description)
                Text(address.markup)
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

struct PetnameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameView(
                petname: Petname("melville")!,
                address: Slashlink(petname: Petname("melville.bobby.tables")!)
            )
            PetnameView(
                petname: Petname(petnames: [Petname("melville")!, Petname("bobby")!, Petname("tables")!])
            )
            PetnameView(
                petname: Petname(petnames: [Petname("melville")!, Petname("bobby")!, Petname("tables")!])
            )
            .frame(maxWidth: 128)
        }
    }
}
