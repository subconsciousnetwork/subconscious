//
//  DetailToolbarContent.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/15/22.
//

import SwiftUI

/// Toolbar for detail view
struct DetailToolbarContent: ToolbarContent {
    var address: MemoAddress?
    var title: String? = nil
    var onRename: () -> Void
    var onDelete: () -> Void

    //  The Toolbar `.principal` position does not limit its own width.
    //  This results in titles that can overflow and cover up the back button.
    //  To prevent this, we calculate a "good enough" maximum width for
    //  the title bar, here, and set it on the frame.
    //  2022-02-15 Gordon Brander
    /// A static width property that we calculate for the toolbar title.
    private var primaryWidth: CGFloat {
        UIScreen.main.bounds.width - 180
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button(
                action: onRename
            ) {
                OmniboxView(address: address)
                    .frame(width: primaryWidth)
            }
            .disabled(address == nil)
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
            .disabled(address == nil)
        }
    }
}

struct DetailToolbarContent_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack {
                Text("Hello world")
            }
            .toolbar(content: {
                DetailToolbarContent(
                    onRename: {},
                    onDelete: {}
                )
            })
        }
    }
}
