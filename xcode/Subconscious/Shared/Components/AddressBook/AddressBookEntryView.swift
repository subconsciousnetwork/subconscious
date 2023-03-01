//
//  AddressBookEntryView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import SwiftUI

/// Full-sized user card, intended for listing users
struct AddressBookEntryView: View {
    var pfp: Image
    var petname: String
    var did: Did
    
    var body: some View {
        HStack(spacing: AppTheme.unit3) {
            ProfilePic(image: pfp)
            VStack(alignment: .leading) {
                Text(verbatim: petname)
                    .foregroundColor(.buttonText)
                    .fontWeight(.semibold)
                Text(verbatim: did.did)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}

struct AddressBookEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AddressBookEntryView(
            pfp: Image("pfp-dog"),
            petname: "@name",
            did: Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!
        )
    }
}
