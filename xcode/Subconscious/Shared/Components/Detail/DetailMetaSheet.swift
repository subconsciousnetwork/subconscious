//
//  DetailMetaSheet.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI
import ObservableStore

struct DetailMetaSheet: View {
    @ObservedObject var store: Store<DetailModel>
    var untitled: String = "Untitled"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        "Audience",
                        selection: Binding(
                            get: { store.state.audience },
                            send: store.send,
                            tag: DetailAction.updateAudience
                        )
                    ) {
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
                address: store.state.address,
                title: store.state.headers.title,
                fallback: untitled
            )
        )
    }
}

struct DetailActionBottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        DetailMetaSheet(
            store: Store(
                state: DetailModel(),
                environment: AppEnvironment()
            )
        )
    }
}
