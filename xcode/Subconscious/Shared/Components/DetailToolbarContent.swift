//
//  DetailToolbarContent.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/15/22.
//

import SwiftUI

/// Toolbar for detail view
struct DetailToolbarContent: ToolbarContent {
    /// Link to currently active entry, if any.
    /// The toolbar decorator does not allow for control flow statements.
    /// That means we have to deal with non-existence within this
    /// toolbar content view, instead of within the toolbar decorator.
    var link: EntryLink?
    var onRename: () -> Void
    var onDelete: () -> Void

    //  The Toolbar `.principal` position does not limit its own width.
    //  This results in titles that can overflow and cover up the back button.
    //  To prevent this, we calculate a "good enough" maximum width for
    //  the title bar, here, and set it on the frame.
    //  2022-02-15 Gordon Brander
    /// A static width property that we calculate for the toolbar title.
    private var titleMaxWidth: CGFloat {
        UIScreen.main.bounds.width - 120
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button(
                action: onRename
            ) {
                if let link = link {
                    ToolbarTitleGroupView(
                        title: Text(link.title),
                        subtitle: Text(String(describing: link.address.slug))
                    )
                    .frame(maxWidth: titleMaxWidth)
                } else {
                    ToolbarTitleGroupView(
                        title: Text("Untitled"),
                        subtitle: Text("")
                    )
                    .frame(maxWidth: titleMaxWidth)
                }
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu(
                content: {
                    Section {
                        Button(
                            action: onRename
                        ) {
                            Label("Rename", systemImage: "pencil")
                        }
                    }
                    Section {
                        Button(
                            action: onDelete
                        ) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                },
                label: {
                    Image(systemName: "ellipsis.circle")
                }
            )
        }
    }
}
