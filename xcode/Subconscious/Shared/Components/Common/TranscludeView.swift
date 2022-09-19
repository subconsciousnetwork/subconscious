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
                SubtextFile(
                    slug: Slug("meme")!,
                    content: """
                    Title: Meme
                    Modified: 2022-08-23
                    
                    The gene, the DNA molecule, happens to be the replicating entity that prevails on our own planet. There may be others.
                    """
                )
            )
        )
    }
}
