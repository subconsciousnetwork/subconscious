//
//  DetailEditToolbarContent.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI

/// Toolbar for detail view
struct DetailEditToolbarContent: ToolbarContent {
    var address: MemoAddress? = nil
    var title: String? = nil
    var onDone: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            OmniboxView(address: address)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: onDone) {
                Text("Done").bold()
            }
        }
    }
}
struct DetailEditToolbarContent_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack {
                Text("Hello world")
            }
            .toolbar(content: {
                DetailEditToolbarContent(
                    onDone: {}
                )
            })
        }
    }
}

