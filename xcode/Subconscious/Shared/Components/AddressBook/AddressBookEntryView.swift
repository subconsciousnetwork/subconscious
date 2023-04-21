//
//  AddressBookEntryView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import SwiftUI

/// Full-sized user card, intended for listing users
struct AddressBookEntryView: View {
    var petname: Petname
    var did: Did
    
    var body: some View {
        HStack(spacing: AppTheme.unit3) {
            VStack(alignment: .leading, spacing: AppTheme.unit) {
                PetnameBylineView(petname: petname)
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
            petname: Petname("name")!,
            did: Did("did:key:z6x")!
        )
    }
}
