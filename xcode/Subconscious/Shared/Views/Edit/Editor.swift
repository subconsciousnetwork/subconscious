//
//  Editor.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/12/21.
//

import SwiftUI

struct Editor: View {
    @Binding var title: String
    @Binding var text: String
    @Binding var isPresented: Bool
    var save: LocalizedStringKey = "Create"
    var cancel: LocalizedStringKey = "Cancel"
    var edit: LocalizedStringKey = "Edit"
    var titlePlaceholder: LocalizedStringKey = "Title"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(cancel) {
                    self.isPresented = false
                }
                Spacer()
                Button(action: {
                    
                }) {
                    Text(save)
                }
            }.padding(16)
            TextField(titlePlaceholder, text: $title)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Divider()
            TextEditor(text: $text)
                // Note that TextEditor has some internal padding
                // about 4px, eyeballing it with a straightedge.
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
        }
    }
}

struct Editor_Previews: PreviewProvider {
    static var previews: some View {
        Editor(
            title: .constant(""),
            text: .constant(""),
            isPresented: .constant(true)
        )
    }
}
