//
//  DetailMetaSheet.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI

struct DetailMetaSheet: View {
    var address: MemoAddress?
    var title: String?
    var untitled: String = "Untitled"
    @State private var audience: Audience = .public

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Audience", selection: $audience) {
                        Text("Everyone").tag(Audience.public)
                        Text("Local").tag(Audience.local)
                    }
                    .pickerStyle(.navigationLink)
                }
                Section {
                    Button(
                        action: {}
                    ) {
                        Text("Rename")
                    }
                    Button(
                        role: .destructive,
                        action: {}
                    ) {
                        Text("Delete")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .navigationTitle(
            Prose.chooseTitle(
                address: address,
                title: title,
                fallback: untitled
            )
        )
    }
}

struct DetailActionBottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        DetailMetaSheet(
            address: MemoAddress.local(Slug("the-whale-the-whale")!)
        )
    }
}
