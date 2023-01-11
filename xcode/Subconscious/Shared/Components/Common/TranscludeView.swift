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
        .overlay(
            RoundedRectangle(
                cornerRadius: AppTheme.cornerRadiusLg
            )
            .stroke(Color.separator, lineWidth: 1)
        )
    }
}

struct TranscludeView_Previews: PreviewProvider {
    static var previews: some View {
        TranscludeView(
            entry: EntryStub(
                MemoEntry(
                    slug: Slug("meme")!,
                    contents: Memo(
                        contentType: ContentType.subtext.rawValue,
                        created: Date.now,
                        modified: Date.now,
                        title: "Meme",
                        fileExtension: ContentType.subtext.fileExtension,
                        other: [],
                        body: """
                        Title: Meme
                        Modified: 2022-08-23
                        
                        The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.

                        But do we have to go to distant worlds to find other kinds of replicator and other, consequent, kinds of evolution? I think that a new kind of replicator has recently emerged on this very planet. It is staring us in the face.
                        """
                    )
                )
            )
        )
    }
}
