//
//  TranscludeListView.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/11/23.
//

import SwiftUI

struct TranscludeListView: View {
    var entries: [EntryStub]
    var onLink: (EntryLink) -> Void
    
    var body: some View {
        VStack {
            ForEach(entries, id: \.self) { entry in
                TranscludeView(
                    entry: entry,
                    onLink: onLink
                )
            }
        }
    }
}

struct TranscludeListView_Previews: PreviewProvider {
    static var previews: some View {
        TranscludeListView(
            entries: [
                EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("did:subconscious:local/loomings")!,
                    excerpt: Subtext(
                        markup: """
                              Call me Ishmael.
                              Some years ago- never mind how long precisely
                              """
                    ),
                    isTruncated: false,
                    modified: Date.now
                ),
            ],
            onLink: { _ in }
        )
    }
}
