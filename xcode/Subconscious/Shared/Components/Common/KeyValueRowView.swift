//
//  KeyValueRowView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI

/// A row that displays a key and a value (secondary)
struct KeyValueRowView<Key, Value>: View
where Key: View, Value: View {
    var key: Key
    var value: Value

    var body: some View {
        HStack {
            key
            Spacer()
            value.foregroundColor(.secondary)
        }
        .lineLimit(1)
    }
}

struct KeyValueView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueRowView(
            key: Text("Key"),
            value: Text("Value")
        )
    }
}
