//
//  IconLabelRow.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/14/21.
//

import SwiftUI

struct IconLabelRowView: View {
    var title: String
    var image: Image
    var titleColor: Color = Constants.Color.text
    var iconColor: Color = Constants.Color.accent

    var body: some View {
        Label {
            Text(title).foregroundColor(titleColor)
        } icon: {
            IconView(image: image).foregroundColor(iconColor)
        }
        .lineLimit(1)
    }
}

struct IconLabelRow_Previews: PreviewProvider {
    static var previews: some View {
        IconLabelRowView(
            title: "Some title",
            image: Image(systemName: "folder")
        )
    }
}
