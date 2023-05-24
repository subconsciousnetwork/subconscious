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
    
    var identifier: String {
        address?.petname?.markup ?? address?.markup ?? petname.markup
    }
    
    var body: some View {
        if address != nil {
            VStack(alignment: .leading) {
                Text(petname.description)
                Text(identifier)
                    .foregroundColor(.secondary)
                    .fontWeight(.regular)
                    .font(.caption)
            }
        } else {
            Text(identifier)
                .lineLimit(1)
        }
    }
}

struct PetnameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameView(
                address: Slashlink(petname: Petname("melville.bobby.tables")!),
                petname: Petname("melville")!
            )
            PetnameView(
                petname: Petname("bobby.tables")!
            )
            PetnameView(
                petname: Petname("tables")!
            )
            .frame(maxWidth: 128)
        }
    }
}
