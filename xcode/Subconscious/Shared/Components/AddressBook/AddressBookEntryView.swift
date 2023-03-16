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
    var petname: Petname
    var did: Did
    
    var body: some View {
        HStack(spacing: Unit.three) {
            ProfilePic(image: pfp)
            VStack(alignment: .leading, spacing: Unit.unit) {
                Text(verbatim: "@\(petname.verbatim)")
                    .foregroundColor(.buttonText)
                    .fontWeight(.semibold)
                Text(verbatim: did.did)
                    .foregroundColor(.secondary)
                    .font(.caption.monospaced())
            }
            Spacer()
        }
    }
}

struct AddressBookEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AddressBookEntryView(
            pfp: Image("pfp-dog"),
            petname: Petname("name")!,
            did: Did("did:key:z6x")!
        )
    }
}
