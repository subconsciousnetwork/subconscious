//
//  EditableEntryView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/23/21.
//

import SwiftUI

struct EditableEntryListView: View {
    var entries: [EntryFile]
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ForEach(entries) { entryFile in
                    DynamicTextViewRepresentable(
                        text: Binding(
                            get: { entryFile.entry.content },
                            set: { _ in
                                print("Hello")
                            }
                        ),
                        fixedWidth: geometry.size.width
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    Divider()
                }
            }
        }
        .padding()
    }
}

struct EditableEntryView_Previews: PreviewProvider {
    static var previews: some View {
        EditableEntryListView(
            entries: [
                EntryFile(
                    url: URL(fileURLWithPath: "example.subtext"),
                    content:
                    """
                    Long-range planning does not deal with future decisions, but with the future of present decisions.
                    
                    Peter Drucker
                    """
                ),
                EntryFile(
                    url: URL(fileURLWithPath: "example2.subtext"),
                    content:
                    """
                    Ashby’s Law of Requisite Variety:

                    If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled.

                    Short: The variety of a regulator must be at least
                    as large as that of the system it regulates.

                    Shorter: [[Only variety can absorb variety]].
                    """
                )
            ]
        )
    }
}
