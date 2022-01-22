//
//  TitleGroup.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

/// A title/subtitle pair.
/// Often used in list views.
/// Each line is at least 1 icon in height.
struct TitleGroup: View {
    var title: String
    var subtitle: String
    var lineHeight: CGFloat = AppTheme.icon

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).foregroundColor(Color.text)
                Spacer()
            }
            .frame(minHeight: lineHeight)
            HStack {
                Text(subtitle).foregroundColor(Color.secondaryText)
                Spacer()
            }
            .frame(minHeight: lineHeight)
        }
    }
}

struct TitleGroup_Previews: PreviewProvider {
    static var previews: some View {
        TitleGroup(
            title: "Foo",
            subtitle: "Bar"
        )
    }
}
