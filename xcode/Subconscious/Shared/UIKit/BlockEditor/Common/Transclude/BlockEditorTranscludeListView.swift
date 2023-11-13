//
//  BlockEditorTranscludeListView.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/13/23.
//

import SwiftUI

/// A configured transclude list view suitable for embedding in block cells.
/// UIHostingController requires a concrete type, making view decorators like
/// padding impractical on the UIKit side. To work around this, we create a
/// wrapper view that applies any needed transformations to the view, and
/// gives this configured view a concrete type.
extension BlockEditor {
    struct TranscludeListView: View {
        var entries: [EntryStub]
        var onViewTransclude: (EntryStub) -> Void
        var onTranscludeLink: (ResolvedAddress, SubSlashlinkLink) -> Void

        var body: some View {
            Subconscious.TranscludeListView(
                entries: entries,
                onViewTransclude: onViewTransclude,
                onTranscludeLink: onTranscludeLink
            )
            .padding(.vertical, AppTheme.unit2)
            .padding(.horizontal, AppTheme.padding)
        }
    }
}

struct BlockTranscludeListView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BlockEditor.TranscludeListView(
                entries: [
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink("@handle/short")!,
                        excerpt: Subtext(markup: "Short"),
                        isTruncated: false,
                        modified: Date.now
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink("/loomings")!,
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        isTruncated: false,
                        modified: Date.now
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink(slug: Slug(formatting: "The Lee Shore")!),
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        isTruncated: false,
                        modified: Date.now
                    ),
                ],
                onViewTransclude: { _ in },
                onTranscludeLink: { _, _ in}
            )
        }
        .background(.gray)
    }
}
