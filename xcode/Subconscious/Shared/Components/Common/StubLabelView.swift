//
//  StubLabelView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/22.
//

import SwiftUI

/// A basic label with icon, title, subtitle
struct StubLabelView: View {
    var icon: Image
    var title: String
    var subtitle: String
    var body: some View {
        Label(
            title: {
                TitleGroup(
                    title: title,
                    subtitle: subtitle
                )
            },
            icon: { icon }
        )
    }
}

struct StubLabelView_Previews: PreviewProvider {
    static var previews: some View {
        StubLabelView(
            icon: Image("doc"),
            title: "Title",
            subtitle: "Subtitle"
        )
    }
}
