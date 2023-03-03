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

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button(
                action: onRename
            ) {
                OmniboxView(address: address)
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
