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
    var iconColor = Color.secondaryIcon

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: spacing) {
            configuration.icon
                .frame(
                    width: AppTheme.icon,
                    height: AppTheme.icon
                )
                .foregroundColor(iconColor)
            configuration.title
                .foregroundColor(Color.text)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
        }
    }
}
