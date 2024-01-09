//
//  BlockEditorTranscludeListView.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/13/23.
//

import SwiftUI

extension BlockEditor {
    enum TranscludeListAction {
        case requestLink(EntryLink)
    }
}

/// A configured transclude list view suitable for embedding in block cells.
/// UIHostingController requires a concrete type, making view decorators like
/// padding impractical on the UIKit side. To work around this, we create a
/// wrapper view that applies any needed transformations to the view, and
/// gives this configured view a concrete type.
extension BlockEditor {
    struct TranscludeListView: View {
        var entries: [EntryStub]
        var send: (TranscludeListAction) -> Void
        var body: some View {
            Subconscious.TranscludeListView(
                entries: entries,
                onLink: { link in
                    send(.requestLink(link))
                }
            )
            .padding(.vertical, AppTheme.unit2)
            .padding(.horizontal, AppTheme.padding)
        }
    }
}

extension UIHostingView where Content == BlockEditor.TranscludeListView {
    /// Define a custom update function for UIHostintViews with
    /// TranscludeListView. Will automatically hide view if no entries.
    func update(
        parentController: UIViewController,
        entries: [EntryStub],
        send: @escaping (BlockEditor.TranscludeListAction) -> Void
    ) {
        // Hide if empty
        self.isHidden = entries.isEmpty
        self.update(
            parentController: parentController,
            rootView: BlockEditor.TranscludeListView(
                entries: entries,
                send: send
            )
        )
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
                        modified: Date.now,
                        headers: WellKnownHeaders.emptySubtext
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink("/loomings")!,
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        modified: Date.now,
                        headers: WellKnownHeaders.emptySubtext
                    ),
                    EntryStub(
                        did: Did.dummyData(),
                        address: Slashlink(slug: Slug(formatting: "The Lee Shore")!),
                        excerpt: Subtext(
                            markup: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi."
                        ),
                        modified: Date.now,
                        headers: WellKnownHeaders.emptySubtext
                    ),
                ],
                send: { action in }
            )
        }
        .background(.gray)
    }
}
