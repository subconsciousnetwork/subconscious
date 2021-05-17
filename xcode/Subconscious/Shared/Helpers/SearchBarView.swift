//
//  SearchInputView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI


struct SearchBarView: View {
    /// `isOpen` is essentially focused mode, but doesn't necessitate actual
    /// input focus.
    @Binding var comittedQuery: String
    @Binding var liveQuery: String
    @Binding var isOpen: Bool
    var placeholder: LocalizedStringKey = "Search"
    var cancel: LocalizedStringKey = "Cancel"

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")

                TextField(
                    placeholder,
                    text: $liveQuery,
                    onCommit: {
                        self.comittedQuery = self.liveQuery
                        self.isOpen = false
                    }
                )
                .foregroundColor(.Subconscious.text)
                .transition(.move(edge: .trailing))
                    .onTapGesture {
                        self.isOpen = true
                    }

                if isOpen && !liveQuery.isEmpty {
                    Button(action: {
                        self.liveQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
            .padding(
                EdgeInsets(
                    top: 6,
                    leading: 8,
                    bottom: 6,
                    trailing: 8
                )
            )
            .foregroundColor(Color.Subconscious.secondaryIcon)
            .background(Color.Subconscious.inputBackground)
            .cornerRadius(8.0)
            
            if isOpen {
                Button(action: {
                    self.isOpen = false
                    self.liveQuery = self.comittedQuery
                }) {
                    Text(cancel)
                }
            }
        }
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SearchBarView(
                comittedQuery: .constant(""),
                liveQuery: .constant(""),
                isOpen: .constant(false)
            )
            SearchBarView(
                comittedQuery: .constant("Example"),
                liveQuery: .constant("Example"),
                isOpen: .constant(true)
            )
        }
    }
}
