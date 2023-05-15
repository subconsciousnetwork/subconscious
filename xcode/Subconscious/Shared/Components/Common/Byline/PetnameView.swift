//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

/// Byline style for displaying a petname
struct PetnameView: View {
    var nickname: Petname
    var petname: Petname?
    
    var body: some View {
        if let petname = petname {
            VStack(alignment: .leading) {
                Text(nickname.description)
                Text(petname.markup)
                    .foregroundColor(.secondary)
                    .fontWeight(.regular)
                    .font(.caption)
            }
        } else {
            Text(nickname.markup)
                .lineLimit(1)
        }
    }
}

struct PetnameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PetnameView(
                nickname: Petname("melville")!,
                petname: Petname("melville.bobby.tables")!
            )
            PetnameView(
                nickname: Petname(petnames: [Petname("melville")!, Petname("bobby")!, Petname("tables")!])
            )
            PetnameView(
                nickname: Petname(petnames: [Petname("melville")!, Petname("bobby")!, Petname("tables")!])
            )
            .frame(maxWidth: 128)
        }
    }
}
