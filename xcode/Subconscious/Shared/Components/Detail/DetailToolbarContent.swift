//
//  DetailToolbarContent.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/15/22.
//

import SwiftUI

/// Toolbar for detail view
struct DetailToolbarContent: ToolbarContent {
    var title: String? = nil
    var slug: String? = nil
    var onRename: () -> Void
    var onDelete: () -> Void
    var untitled = "Untitled"

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
                ToolbarTitleGroupView(
                    title: Text(title ?? untitled),
                    subtitle: Text(slug?.description ?? "none")
                )
                .frame(maxWidth: titleMaxWidth)
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
