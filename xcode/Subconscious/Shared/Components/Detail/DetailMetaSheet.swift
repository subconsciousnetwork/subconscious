//
//  DetailMetaSheet.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI
import ObservableStore

struct DetailMetaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: Store<DetailModel>
    var untitled: String = "Untitled"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    SlashlinkBylineView(slashlink: Slashlink("@gordonbrander/foo")!)
                    AudienceMenuButtonView(
                        audience: Binding(
                            get: { store.state.audience },
                            send: store.send,
                            tag: DetailAction.updateAudience
                        )
                    )
                }
                Spacer()
                CloseButtonView(action: { dismiss() })
            }
            .padding()
            Divider()
            Form {
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
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium, .large])
    }
}

struct DetailActionBottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
        }
        .sheet(isPresented: .constant(true)) {
            DetailMetaSheet(
                store: Store(
                    state: DetailModel(
                        address: MemoAddress.local(Slug("the-whale-the-whale")!),
                        editor: SubtextTextModel(
                            text: ""
                        )
                    ),
                    environment: AppEnvironment()
                )
            )
        }
    }
}
