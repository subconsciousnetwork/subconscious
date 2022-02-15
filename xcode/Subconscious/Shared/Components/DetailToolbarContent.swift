//
//  DetailToolbarContent.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/15/22.
//

import SwiftUI

/// Toolbar for detail view
struct DetailToolbarContent: ToolbarContent {
    var isEditing: Bool
    var title: String
    var slug: Slug?
    var onRename: (Slug?) -> Void
    var onDone: () -> Void

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
            if !isEditing {
                Button(
                    action: {
                        onRename(slug)
                    }
                ) {
                    ToolbarTitleGroupView(
                        title: title,
                        slug: slug
                    )
                    .frame(maxWidth: titleMaxWidth)
                }
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if isEditing {
                HStack {
                    Button(
                        action: onDone
                    ) {
                        Text("Done").bold()
                    }
                    .foregroundColor(.buttonText)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .transition(.opacity)
                }
            } else {
                HStack{
                    EmptyView()
                }
                .frame(width: 24, height: 24)
            }
        }
    }
}
