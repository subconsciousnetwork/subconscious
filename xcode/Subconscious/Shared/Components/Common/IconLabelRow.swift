//
//  IconLabelRow.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/14/21.
//

import SwiftUI

struct IconLabelRow: View {
    var title: String
    var image: Image

    var body: some View {
        Label {
            Text(title).foregroundColor(.Sub.text)
        } icon: {
            Icon(image: image).foregroundColor(.accentColor)
        }
        .lineLimit(1)
    }
}

struct IconLabelRow_Previews: PreviewProvider {
    static var previews: some View {
        IconLabelRow(
            title: "Some title",
            image: Image(systemName: "folder")
        )
    }
}
