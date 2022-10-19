//
//  TranscludeView.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/23/22.
//

import SwiftUI

struct TranscludeView: View {
    var entry: EntryStub

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            HStack {
                Text(entry.linkableTitle)
                    .bold()
                Spacer()
            }
            Text(entry.excerpt)
        }
        .padding(.vertical, AppTheme.unit3)
        .padding(.horizontal, AppTheme.unit4)
        .background(Color.secondaryBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct TranscludeView_Previews: PreviewProvider {
    static var previews: some View {
        TranscludeView(
            entry: EntryStub(
                SubtextEntry(
                    slug: Slug("meme")!,
                    contents: Memo(
                        headers: Headers(),
                        contents: Subtext(
                            markup: """
                            Title: Meme
                            Modified: 2022-08-23
                            
                            The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.

                            But do we have to go to distant worlds to find other kinds of replicator and other, consequent, kinds of evolution? I think that a new kind of replicator has recently emerged on this very planet. It is staring us in the face.
                            """
                        )
                    )
                )
            )
        )
    }
}
