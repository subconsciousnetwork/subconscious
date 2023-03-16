//
//  SuggestionLabelStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

/// Creates label style analogous to a default list label
/// However, this version gives us more control over the styling, allowing us to create hanging icons.
struct SuggestionLabelStyle: LabelStyle {
    var spacing: CGFloat? = nil
    var iconColor = Color.icon

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: spacing) {
            configuration.icon
                .frame(
                    width: Unit.icon,
                    height: Unit.icon
                )
                .foregroundColor(iconColor)
            configuration.title
                .foregroundColor(Color.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
        }
    }
}
